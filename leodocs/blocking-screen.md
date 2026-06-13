# The "blocking screen" during a remote (desktop↔mobile) session

> What it is, **why** it exists, whether it protects anything, and **what it would
> actually take to alter or remove it.** Grounded in the code with file:line pointers.

---

## 0. Context of this investigation

This came out of a longer design discussion about using SimpleX from Linux/desktop
(see `use-from-desktop-ux.md` and `syncthing-complexity.md`). Observed behaviour:

> When the desktop is connected to (controlling) the Android app, the **phone shows a
> screen where you can't do anything until you disconnect.**

The questions were: **is that just a UX convention, or is it protecting the database?**
And **what would happen if both the desktop and the phone showed a live UI at the same
time?** Short answers, established below:

- It is **not** a database-safety guard. A remote session is **one core, one DB** — no
  corruption is possible. (This is the opposite of the DB-sync scenario in
  `syncthing-complexity.md`, which genuinely *can* corrupt and genuinely *does* need a
  hard block.)
- The real reason is the **single-consumer event stream**: the core has one event
  queue, it's drained to feed the desktop during a session, and a second live UI
  cannot be fed consistently from it.
- Two live UIs would produce **incoherent views, not data corruption.**
- Removing the block is therefore a **feasible, self-contained change** — but it
  requires **event fan-out** in the core (or a client-side workaround), not just
  deleting the UI.

---

## 1. The architecture: who holds what

Roles (verified — see `use-from-desktop-ux.md` §0/§8 for the role/transport details):

- **Phone = remote _host_** — holds the **account, the database, and the running
  core.** It is the TLS *client* (dials out).
- **Desktop = remote _controller_** — a **thin view.** It is the TLS *server*
  (announces/waits). It sends commands over the encrypted pipe to the phone's core and
  receives events back.

**Crucial consequence:** a remote session has exactly **one core and one SQLite
database**, both on the phone. The desktop never has a second copy. Contrast with the
Syncthing DB-sync idea (`syncthing-complexity.md`), which has *two* cores / *two* DBs
and the double-ratchet fork hazard — **that** is where a hard mutual-exclusion block is
mandatory. Here it is not.

---

## 2. The two channels (this is the key to everything)

The FFI between any UI and the core has **two distinct channels**, not one:

### Channel A — Command → Response (point-to-point, synchronous)
- `chat_send_cmd` / `chat_send_cmd_retry` — UI sends a command, gets a **response back
  directly** (`Mobile.hs:115-117, 182-191`; `chatSendCmd`, `Mobile.hs:337`).
- Responses are the `CR*` constructors of `data ChatResponse` (`Controller.hs:694`).
- This is the *"I asked, here's my answer"* path, addressed only to the caller.

### Channel B — Event stream (broadcast, asynchronous)
- `chat_recv_msg` / `chat_recv_msg_wait` — pulls the next event (`Mobile.hs:123-125,
  207-212`).
- **Single-consumer pull queue:**
  ```haskell
  chatRecvMsg ChatController {outputQ} = ... atomically (readTBQueue outputQ)  -- Mobile.hs:345-348
  ```
  `readTBQueue` **removes** the item and gives it to **exactly one** reader. It is
  **not** a broadcast/fan-out. (One `outputQ` per `ChatController`.)
- Events are the `CEvt*` constructors of `data ChatEvent` (`Controller.hs:850`),
  emitted throughout the core via `toView` (e.g. `Subscriber.hs:143,150,152,179,...`).

---

## 3. What "events" actually are (not just incoming messages)

A common misconception is that the event stream = "messages from the server." It's
actually a **state-change broadcast bus.** Three tiers of "something happened":

1. **Pure UI state — never reaches the core.** Scrolling, opening a chat screen,
   menus, navigation: pure Compose / `ChatModel` state in Kotlin. No command, no event.
2. **Command result — Channel A response.** A data-changing click (send/delete/edit/
   fetch) calls `chat_send_cmd` and the UI uses the **returned response**. Sending a
   message returns `CRNewChatItems`; the Android UI adds the bubble straight from it
   (`SimpleXAPI.kt:1105`, `r.res is CR.NewChatItems`).
3. **Event-stream broadcast — Channel B.** Carries:
   - **Network-originated:** incoming messages, delivery/read receipts, member joins,
     call offers (`CEvtCallOffer`, `CEvtMemberRole`, …).
   - **Locally-originated but async:** file transfer progress
     (`CEvtSndFileProgressXFTP`), subscription/connection status
     (`CEvtSubscriptionStatus`), app lifecycle (`CEvtChatSuspended`), background errors
     (`CEvtChatErrors`). **None of these come from a server** — the core is narrating
     its own local background work.
   - **Echoes of your own commands:** the smoking gun —
     ```haskell
     | CRNewChatItems   {user, chatItems}                                    -- Controller.hs:731
     | CEvtNewChatItems {user, chatItems} -- there is the same command response   -- Controller.hs:857
     ```
     The same "new chat items" exists **both** as a response (to the sender) **and** as
     an event (broadcast to all views). The source comment says so explicitly.

**Takeaway:** the event stream is how **every** state change — network arrivals, local
async work, *and the side effects of your own actions* — propagates to a UI. A UI cut
off from it goes stale even for things *it* did.

---

## 4. Why the blocking screen exists (the real reason)

Put §2 + §3 together:

- During a remote session, the phone's core events are **drained from `outputQ` and
  forwarded to the desktop** so the desktop's view stays live.
- Because `outputQ` is **single-consumer**, if the phone's *local* UI also pulled from
  it, **each event would go to only one of the two** — half to the desktop, half to the
  phone, at random.
- The phone's local UI would then be **missing a random subset of all state changes** —
  including its own sent messages, file progress, receipts, everything (§3).

So the phone shows a **deliberate "you're connected; disconnect to use here" screen**
instead of a **half-updating, inconsistent** one. It's a UX decision **backed by a real
event-routing constraint** — not arbitrary, but also **not a data guard.**

### It is NOT protecting the database
One core serializes every command through one `ChatController`; the store layer handles
its own concurrency. Two UIs both issuing commands to that one core just get
**sequential execution** — the DB stays correct regardless. Nothing about the block is
about data integrity.

---

## 5. What would actually happen if both UIs were live

Not corruption — **incoherence:**

- **Commands** (send/delete/edit) → fine. Serialized through the one core; DB and true
  message state stay correct.
- **Events** → split/raced between the two UIs (§4). Each UI receives a random subset
  and **silently misses the rest**: a message shows on the desktop but never on the
  phone, stale unread counts, missing receipts/status.
- **Underlying data stays correct** — the core processed every event into the DB. Only
  each UI's *displayed view* is incomplete. A re-open / refresh (re-reads from DB)
  shows the truth again.

---

## 6. The state + UI that implement the block (where to look / change)

Phone side (the controlled device — "remote ctrl session"):
- **State:** `chatModel.remoteCtrlSession` (`ChatModel.kt:232`), type `RemoteCtrlSession`
  (`ChatModel.kt:5206`); `active` = `sessionState is UIRemoteCtrlSessionState.Connected`
  (`ChatModel.kt:5212`).
- **Global gate:** `connectedToRemote()` (`ChatModel.kt:1204-1205`) =
  `currentRemoteHost != null || remoteCtrlSession.active`. This is the flag that things
  check to decide "am I in a remote session."
- **The actual screen:** `ConnectDesktopView.kt` →
  `ConnectDesktopLayout` (`:74`) → on `UIRemoteCtrlSessionState.Connected` it renders
  **`ActiveSession(...)`** (`:100`, defined at **`ConnectDesktopView.kt:312`**) — the
  "connected to desktop, here's the session code, [Disconnect]" screen. `disconnectDesktop`
  tears the session down (`:548-551`, sets `remoteCtrlSession.value = null`).

Desktop side (the controller — "remote host"):
- **State:** `chatModel.currentRemoteHost` / `chatModel.remoteHosts`; switch active view
  with `switchUIRemoteHost(remoteHostId | null)` (`ConnectMobileView.kt:69`). The desktop
  shows **one** of {its own local account, a connected phone} at a time — never two.

---

## 7. What it would take to alter or REMOVE the block

The block is a **design choice, not a safety wall** — so it's removable. The difficulty
is entirely about the **single-consumer event stream**, which must be solved first, or
both UIs will desync (§5).

### Option A — Event fan-out in the core (the proper fix) 🟠
Make the core **broadcast** events to multiple consumers instead of a single `outputQ`
pull. Concretely: replace the single `readTBQueue outputQ` consumer model with a
fan-out (e.g. a broadcast/`dupTChan`-style structure, or per-subscriber queues) so the
**local UI and the remote-forwarder each get a full copy** of every event.
- Touches: `ChatController.outputQ` and everything that does `toView`/`readChatResponse`
  (`Mobile.hs:345-348`), plus the remote-host forwarding path.
- Risk: it's a core concurrency change; must preserve ordering and not drop events;
  affects the CLI/WS server too (they also pull `outputQ`).
- Payoff: both phone and desktop can run **live, consistent** UIs simultaneously off the
  same one core — no block needed, and **no DB risk** (still one core, one DB).

### Option B — Client-side: keep the block off but accept staleness 🟡
Leave the core single-consumer; let the phone show its UI during a session but treat it
as **read-mostly / best-effort**, refreshing from the DB (re-running `apiGetChat`/
`apiGetChats`, which is Channel A and always correct) on focus/interaction instead of
relying on the event stream. Cheaper, but the phone's live updates would lag/miss
events; you'd be papering over §5 rather than fixing it.

### Option C — Just delete the screen (do NOT) 🔴
Removing the `ActiveSession` gate without addressing the event stream gives you exactly
the §5 incoherence: a phone UI that silently misses half of all updates. The data is
safe, but the UX is broken and confusing. Not recommended.

### Things that are **safe** regardless (no DB concern)
- Allowing **commands** from the phone during a session (DB serializes them).
- Allowing **read-only** phone views (reading from the DB via Channel A is always
  correct).
- Keeping the pipe open while also using the phone (no single-writer rule here — that's
  only the DB-sync track).

### Recommended path
If the goal is "use the phone *and* desktop at once," do **Option A** — it's the only
one that yields a correct live experience, and it's self-contained to the event-queue
machinery. If the goal is just "don't trap me on a dead screen," **Option B** (read
from DB on the phone, best-effort live) is a lighter, lower-risk step.

---

## 8. One-paragraph summary

The blocking screen is a **UX convention backed by a real constraint — the core's
single-consumer event stream — not a database safeguard.** A remote session is one
core / one DB on the phone, so there is **zero corruption risk**; two live UIs would
merely **desync visually** because each event (`CEvt*`, including echoes of your own
commands — `Controller.hs:857`) is delivered to only one reader (`readTBQueue outputQ`,
`Mobile.hs:345`). Removing the block cleanly means giving the core **event fan-out**
(Option A) so both the phone (`ConnectDesktopView.ActiveSession`, gated by
`remoteCtrlSession` / `connectedToRemote()`) and the desktop can each receive a full
copy of the event stream. Everything else about concurrent use — commands, reads,
keeping the pipe open — is already safe.
