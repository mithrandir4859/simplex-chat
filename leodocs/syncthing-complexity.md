# Syncthing-based DB sync for SimpleX Chat — complexity analysis

> Goal under analysis: keep the SimpleX local database synchronized "semi-live"
> across a laptop + Android + **any number of clients**, using **Syncthing** as the
> transport, with a **strict single-active-client** model. Inactive clients are
> hard-paused; switchover may take 3–40 s; we accept that and the user-driven
> geofence logic (e.g. "phone leaves home → force-pause desktop → hand DB to phone").
>
> This document enumerates *every* issue you'd have to solve, grounded in the actual
> code, with severity and mitigation. It is a feasibility + design-risk map, not an
> implementation.

---

## 0. TL;DR / verdict

**It is feasible, and your chosen model (strict single-writer + full-DB handoff +
fail-closed) is the *only correct* model** — SimpleX's protocol forbids anything
softer. But the difficulty is **not** in Syncthing or in export speed (the things
you flagged). The real difficulty is a **classic distributed-mutex problem over an
eventually-consistent file store**, where the cost of getting the mutex wrong is
**silent, permanent, unrecoverable data corruption** (double-ratchet desync), not a
mere conflict you can clean up later.

So the project is really: *"build a correct, fail-closed, single-leader handoff
protocol on top of Syncthing, where 'two leaders for even one second' = corruption."*
Everything else (export, file sync, path portability) is comparatively easy and
mostly already supported.

**Severity legend:** 🔴 showstopper-class (get it wrong = data loss) · 🟠 hard but
solvable · 🟡 annoyance / engineering · 🟢 already handled / easy.

---

## 1. Why this is fundamentally hard (the protocol, not the tooling)

SimpleX has **no server-side account and no server-side source of truth.** Your
entire identity *is* the local database. There are **two** SQLCipher DB files
(verified in `Files.android.kt` / `Files.desktop.kt`):

| DB | Holds | Sync danger |
|---|---|---|
| `*_chat.db` | chat items, contacts, groups, profiles, settings | mostly additive; conflicts are "lost edits", survivable |
| `*_agent.db` | **SMP queue keys, double-ratchet state, connection state, msg delivery/ack bookkeeping** | **state machine that advances destructively — the landmine** |

Three protocol facts make naïve multi-device sync impossible, and force the
single-writer model:

### 1a. 🔴 Double-ratchet state is single-owner and advances destructively
E2E encryption uses the Double Ratchet (in the agent / `simplexmq`). Every message
sent/received **mutates** the ratchet (chain keys, message keys, header keys).
The state lives in `*_agent.db`. If **two clients ever hold the same ratchet state
and both send or receive**, their ratchets diverge and messages encrypted by one
become **permanently undecryptable** by the peer's expectation of the other — there
is **no merge and no repair** short of re-establishing the connection out of band.
This is why "just sync both DBs and let both run" is not an option, ever, even for
one second.

### 1b. 🔴 SMP queue draining is destructive and single-subscriber
Receiving a message from an SMP server **ACKs and deletes it server-side**. Whoever
drains the queue *wins*; any other client that wasn't the active one will **never see
those messages** — they're gone from the server. Therefore **the DB that received a
message is the only copy of it.** A handoff MUST capture every received message
before the next client activates, or messages vanish. (The agent even has explicit
duplicate/replay handling — `A_DUPLICATE` in `Subscriber.hs:692` — a hint at how
carefully reception is single-tracked.)

### 1c. 🔴 There is no DB merge function
Two diverged SQLCipher DBs cannot be 3-way merged — not by you, not by SimpleX, not
by Syncthing. A Syncthing `.sync-conflict-*` on a DB file is **not recoverable**:
you must pick one and discard the other = data loss, *and* likely ratchet corruption
on top. So the design must **prevent divergence entirely**, not reconcile it.

**Consequence:** the only safe invariant is **"at most one core has the DB open and
is subscribed, at any instant, globally."** Your whole system exists to enforce that
invariant over a transport (Syncthing) that **cannot give you atomic mutual
exclusion**. That tension is the entire problem.

---

## 2. What exactly must be synchronized

- `*_chat.db` and `*_agent.db` (both — they're a consistent pair; never sync one without the other) 🔴
- The `files/` media directory (received/sent attachments, encrypted CryptoFiles). 🟢 **Good news:** the DB stores media by **relative filename** (`Store/Files.hs` uses `takeFileName`; the client resolves via `getAppFilePath(fileName)` = `appFilesDir + name`, `Files.kt:83`). So files are **path-portable across Android/Linux** as long as the filename is preserved.
- Your own control/lock/manifest files (the handoff metadata — see §4).

**NOT to sync:** WAL/SHM sidecar files mid-flight, temp dirs, anything while a core has the DB open.

---

## 3. Cross-platform & versioning landmines

### 3a. 🟠 DB filenames differ per platform
- Android: `files_chat.db` / `files_agent.db`, opened with prefix `files`
- Desktop: `simplex_v1_chat.db` / `simplex_v1_agent.db`, opened with prefix `simplex_v1`

(`chat_migrate_init` takes a path *prefix*; `Files.*.kt`.) So you **cannot** sync raw
files verbatim and have both sides open them by their expected name. Two options:
- **(A) Rename on import** — sync a canonical pair, rename to the platform's expected
  names before `chat_migrate_init`. Simple, but you own the renaming + atomicity.
- **(B) Use the archive (`APIExportArchive`/`APIImportArchive`)** — abstracts the
  filenames; the archive is the portable unit. Heavier (full rewrite each handoff).

### 3b. 🔴 Schema version must be lock-step across all clients
Migrations are **forward-only** (`Store/SQLite/Migrations/`). If the laptop app
migrates the DB to schema vN and an Android client only supports vN-1, the Android
client **cannot open it** (and `chat_migrate_init` is called with
`MigrationConfirmation.Error` by default — it will refuse). With "any number of
clients," **every client must be on the same app version** before any of them
migrates the shared DB. An auto-update on one device can brick the others until they
update. You need a version gate in the handoff (refuse to activate if the synced DB
schema > my supported schema).

### 3c. 🟡 SQLCipher key must be identical everywhere
All clients open with the same passphrase/key. Fine, but it means provisioning the
key to every device securely (and Syncthing syncs only the *encrypted* bytes, which
is good for confidentiality but see §6c on delta size).

---

## 4. The handoff protocol (the actual work)

This is the heart of the project. You're building a **single-leader lease protocol**
where the log is a set of Syncthing-replicated files. Sketch of a *correct* handoff
(laptop → phone), with the failure-guards that make it safe:

```
Invariant: exactly one holder of the "lease", and the DB is only opened by the lease holder.

1. Phone wants in (e.g. geofence: left home):
     phone writes  request.json  {wantOwner: "phone", gen: N, ts}
2. Laptop observes request (Syncthing delivers, 3–20s):
     a. stop receive loop  (apiStopChat / stop subscriber)
     b. chat_close_store    ← flushes + releases file locks (verified FFI, Mobile.hs:111)
     c. checkpoint/close WAL so the .db files are self-contained
     d. compute hash(chat.db)+hash(agent.db)+files-manifest
     e. write  lease.json  {owner: "none", lastOwner: "laptop", gen: N,
                            dbHash, filesManifestHash, releasedAt}
3. Syncthing propagates the DB files + lease.json (3–20s, maybe minutes on Doze).
4. Phone activation gate — ALL must hold before opening DB:
     - sees lease.owner=="none" AND lease.gen==N AND lease.lastOwner=="laptop"
     - Syncthing reports this folder 100% in-sync (via Syncthing REST/events API)
     - local hash(chat.db,agent.db) == lease.dbHash   ← proves files fully arrived
     - schema(db) <= my supported schema              ← §3b gate
   If any fail → WAIT or ABORT (fail-closed). Never open on doubt.
5. Phone takes lease:
     writes lease.json {owner:"phone", gen:N+1, takenAt}
     rename DB to phone's filenames (§3a), chat_migrate_init, start receive loop.
6. Laptop must NOT reopen until it sees gen>N owned by someone else (it already
   released; it stays dark until it re-requests with gen N+2).
```

### Why each guard exists (the non-obvious failures):
- 🔴 **File-arrival ordering is not guaranteed.** Syncthing may deliver `lease.json`
  *before* the large `agent.db` finishes. Without the **hash gate (4c)** the phone
  would open a *stale/truncated* DB → corruption. The hash is your barrier.
- 🔴 **"Is Syncthing done?" is not knowable from the filesystem alone.** You must
  query Syncthing's **REST API / event stream** (`FolderCompletion`, `ItemFinished`)
  to know the folder is fully in-sync for *this* device. Polling mtime is unsafe.
- 🔴 **Generation counter / lease term** prevents a slow/old client from activating
  on stale state (split-brain). Monotonic `gen` + "highest gen wins, ties = nobody".
- 🟠 **WAL checkpoint before release (2c).** With WAL mode the latest writes live in
  `-wal`; if you sync only `.db` you ship a stale DB. Either checkpoint to fold WAL
  into the main file, or sync the `-wal` too (and then atomicity is harder). Closing
  the store (`chat_close_store`) should checkpoint — **verify this in simplexmq**.

### 4b. 🔴 The mutex is the whole ballgame, and Syncthing can't give it to you
A lock *file* over an eventually-consistent store is **advisory and laggy**. Two
clients can both believe they hold it during the propagation window. Mitigations,
none perfect:
- **Asymmetric/leased ownership:** a client may only *take* the lease after observing
  an explicit *release* by the prior owner (not merely "I haven't seen them in a
  while"). No timeout-based stealing in the normal path.
- **Two-phase, request → release → take** (as above) so handoff is *cooperative*,
  not *contended*.
- **Fail-closed everywhere:** if state is ambiguous, **nobody** activates. You
  tolerate downtime; you do not tolerate two leaders. (Messages wait safely on SMP
  servers meanwhile.)
- A **stuck-owner escape hatch** (owner died/offline holding the lease) needs manual
  override, not automatic stealing — automatic stealing reintroduces split-brain.

---

## 5. Syncthing-specific issues

- 🔴 **Eventual consistency / propagation window (3–20s, worse on mobile).** This is
  exactly when split-brain can happen; §4 guards are mandatory.
- 🔴 **Conflict files (`*.sync-conflict-*`).** If two clients ever write the DB, you
  get unmergeable conflict copies = data loss. Your protocol must make concurrent DB
  writes *impossible*, and you should also **alarm** if a `.sync-conflict-*` ever
  appears (it means the invariant was violated).
- 🟠 **Completion detection requires the Syncthing API.** Run Syncthing with its REST
  API enabled and poll `/rest/db/completion` (per folder+device) or subscribe to the
  event stream. Without it you cannot safely know "the DB fully arrived."
- 🟡 **Syncthing must not sync while a core has the DB open.** Either pause the
  Syncthing folder while active, or only ever write DB files when closed. Simplest:
  active client = DB open + Syncthing folder *paused for writes*; on release, close
  DB then resume/trigger sync.
- 🟡 **Atomic file replacement.** Sync to a staging dir, verify hash, then atomically
  rename into place before `chat_migrate_init`. Never import a file Syncthing is
  mid-write on.
- 🟡 **Many clients = N² Syncthing mesh + N copies of a large encrypted DB.** Works,
  but every handoff reshuffles the whole encrypted blob to every node (see §6c).

---

## 6. Database / storage mechanics

- 🟢 **`chat_close_store` / `chat_reopen_store` exist** (`Mobile.hs:111-113`) — the
  lightweight primitive to flush + release the DB without a full archive export.
  This makes **raw-file handoff** (close → sync → rename → open) viable and far
  cheaper than archive export/import per switch.
- 🟠 **Import = stop core → swap DB → start core.** Confirmed in `DatabaseView.kt`
  (`stopChatRunBlockStartChat { importArchive(...) }`). So "unpause" is effectively a
  **chat-controller restart with the new DB**, not a seamless in-place swap. The app
  has the flow, but as a deliberate user action; you'd be automating it.
- 🟠 **Cold-start resubscribe cost.** On activation the agent reconnects to all SMP
  servers and re-subscribes to all queues — this is the bulk of your "3–40s" and
  grows with number of contacts/groups. Acceptable per your tolerance, but it's the
  real latency, not Syncthing.
- 🟠 **WAL atomicity** — see §4 (checkpoint before sync).
- 🟡 **Encryption defeats Syncthing's block-level delta dedup.** SQLCipher re-encrypts
  pages; small logical changes → large ciphertext deltas. Each handoff may resync a
  big fraction of the DB. With big histories + media, your 3–20s assumption can creep
  toward minutes. Keeping `*_chat.db` history pruned and media synced separately helps.

---

## 7. Android-specific issues

- 🔴 **DB swap = controller restart, and you want it triggered in the background**
  (on geofence enter/leave). Android restricts background execution; doing a
  stop→import→start off a geofence event reliably needs a **foreground service** (the
  app already has `SimplexService.kt`) and careful WorkManager orchestration.
- 🟠 **Syncthing on Android is throttled by Doze/battery optimization.** When the
  phone is idle (exactly when you're not using it), sync can stall — your 3–40s
  window can blow out to minutes until the screen wakes. Whitelisting Syncthing from
  battery optimization is required, and even then not guaranteed.
- 🟠 **No notifications on the inactive device — by design.** A paused client doesn't
  subscribe, so it receives nothing. With your geofence model: at home laptop is
  active and the phone is silent/stale; away the phone is active. That's inherent and
  acceptable, but means **the phone shows stale chats until it next becomes active**,
  and you get **no push** for the device that isn't the leader.
- 🟡 **App not designed for its DB to change underneath it.** You'd drive activation
  through the existing stop/import/start path; UI state (`ChatModel`) must be fully
  reloaded after the swap (it is, on chat start).

---

## 8. The geofence / auto-trigger logic (your "force-pause desktop" idea)

- 🟠 **The trigger lives on the phone, but it must command the desktop** over the slow
  Syncthing channel. "Phone left home → write `request.json`" → desktop reacts in
  3–20s. During that window the desktop is **still active** — which is fine *as long
  as activation is gated on the desktop's explicit release* (§4). Never let the phone
  self-activate on a timer; only on observed release. 🔴
- 🟠 **Desktop offline/asleep when phone hands back.** Phone releases, but desktop
  never wakes to take the lease → **nobody is active**. Messages pile up safely on SMP
  servers; you just don't receive until *some* client activates. Handle "no leader"
  as a normal state with a manual/automatic "claim" action. (This is *safe* — it's the
  fail-closed direction.)
- 🟡 **Geofence reliability.** Android geofencing is approximate and power-managed;
  expect missed/delayed triggers. Combine Wi-Fi SSID + location, and make manual
  override always available.
- 🟡 **Flapping.** Walking in/out of range repeatedly could thrash handoffs (each
  costing a resubscribe). Add hysteresis / minimum dwell time before switching.

---

## 9. Failure modes & recovery (design these explicitly)

| Failure | Result | Required handling |
|---|---|---|
| Two leaders for >0s | 🔴 ratchet desync + lost msgs, silent & permanent | Prevent via §4; **alarm on any `.sync-conflict`**; this is the thing the whole design exists to avoid |
| Lease holder dies holding lease | No one can take over (fail-closed) | Manual override / "force claim" (never automatic timeout-steal) |
| Partial sync, flag arrives before DB | Stale/truncated DB opened | Hash/manifest gate (§4c) |
| Schema skew after one app updates | Older clients can't open DB | Version gate; coordinate updates |
| Syncthing conflict on DB | Unmergeable | Must be impossible by construction; if seen, halt + manual recovery from last good |
| Media missing but referenced | Broken attachments (not fatal) | Files sync is portable (§2); tolerate lazily, or gate on files manifest |
| Doze stalls sync | Long switchover | Battery whitelist; accept; show "syncing…" state |

---

## 10. Recommended design (synthesis)

1. **Transport unit:** raw `*_chat.db` + `*_agent.db` + `files/`, synced as one
   Syncthing folder. Use `chat_close_store` + WAL checkpoint to make the pair
   self-consistent before each sync. (Avoid full archive export per-switch; too heavy.)
2. **Canonical filenames** in the synced folder; **rename to platform names on import**
   (§3a). Or accept archive import if renaming proves fragile.
3. **Lease protocol** exactly as §4: request → release(+hash+gen) → gated take. No
   timeout-stealing. Monotonic generation counter. Fail-closed on any ambiguity.
4. **Gate activation** on three signals together: lease state, Syncthing-API
   completion, and local DB hash match. Plus a schema-version gate.
5. **Active client pauses the Syncthing folder for writes** while its DB is open;
   resumes/triggers on release. Guarantees no concurrent writers.
6. **Geofence only writes `request.json`;** the desktop's release is what authorizes
   the phone. "No leader" is a valid, safe resting state.
7. **Alarm loudly** if a `.sync-conflict-*` ever appears (invariant breached) and halt
   automation until manually cleared.
8. **Keep all clients on identical app/schema versions;** gate updates.

---

## 11. Things to verify in `simplexmq` before building (not in this repo)

- Does `closeDBStore` checkpoint/fold the WAL so the on-disk `.db` is complete? (§4/§6)
- Is the SQLCipher DB byte-portable Android↔Linux as-is (it should be — SQLite is
  portable; SQLCipher params must match)? Confirm page size/KDF params are identical
  across the two builds.
- Exact contents of `*_agent.db` that are device/session-local (if any) — e.g. does it
  store anything tied to the device that would misbehave after import? (Ratchet/queue
  state is portable by design, but confirm no device-pinned rows.)
- Behavior of the agent on activation when SMP queues have undelivered messages queued
  during the gap (it should just drain them — that's the normal offline-catchup path).

---

## 12. Bottom line on effort & risk

- **Export/import + file sync + path portability:** 🟢/🟡 mostly supported and easy
  (close_store exists, files are relative-path portable, import flow exists).
- **The lease/handoff protocol over Syncthing:** 🟠 the bulk of the work — a real
  distributed-systems component with hash gates, generation counters, Syncthing-API
  completion checks, and rigorous fail-closed behavior.
- **The thing that can hurt you:** 🔴 a single mutex slip = silent, permanent
  ratchet/message corruption with no merge and no undo. The entire design's job is to
  make "two active cores at once" *structurally impossible*, and to **alarm + halt**
  if it ever detects that it happened.

Your stated tolerances (hard pause, 3–40s delay, manual-ish switching) are exactly
right and make this tractable. The built-in "use from desktop" feature avoids all of
this by never letting the phone own the DB — which is why it feels limited. What you
want is genuinely a small **single-leader replication system**, and it's buildable,
provided you treat the mutex as a correctness problem, not a convenience flag.
