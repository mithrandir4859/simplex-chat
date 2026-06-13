# Cooperative, variable-rate cover on a forked SMP server — v2

> Second version of `forked-server-timing.md`. Same core proposal — a **forked SMP
> server that cooperates with a forked client to produce per-queue, opt-in, *variable*
> (human-shaped) cover traffic**, with client-(semi-)controlled delayed delivery and an
> urgency override — but re-grounded against the **pinned `simplexmq` source**
> (`b981dcb7`, tag 6.5.3.0) and the full RFC/blog corpus. v1's protocol claims hold up;
> what changed is **context**: SimpleX has its *own* name and threat-model slot for this
> idea, several adjacent mechanisms are already designed or shipped, and two hard
> contradictions with the project's direction were not called out in v1.

---

## 0. What changed from v1 (read this first)

This version answers four questions the v1 didn't:

1. **Is fake/dummy/cover traffic ever discussed in SimpleX? — YES, prominently, under the name "noise traffic."** v1 framed cover traffic as an outside idea bolted onto a hostile
   architecture. In fact SimpleX's **own whitepaper and threat model treat "noise traffic"
   / "noise messages" as a first-class, named concept** — byte-indistinguishable from real
   messages (thanks to the 16 KB padded block) and defeatable only by timing. It is
   **specified but never implemented.** See §2.1. This is the single most important
   reframing: the proposal is *aligned with SimpleX's own stated-but-unbuilt design*, not
   working against it. The **specific** form here (per-queue, *variable/human-shaped*,
   *scheduled* cover with real-fits-in-dummy) is **not** planned anywhere — that part is
   greenfield.

2. **Is server-side delayed/scheduled delivery planned? — YES, in detail, but in the
   wrong layer.** The super-peers RFC already defines a `MessageSchedule {deliverAt,
   minDelay, maxDelay}` type *explicitly motivated by traffic-correlation defense* — your
   delayed-delivery idea, already at detailed-design stage. It lives in the super-peer/group
   broadcast layer, not the SMP relay. See §2.4.

3. **Breaking details / contradictions** are now collected in §6. The two that matter:
   **delivery receipts** (a fatal real-only tell — confirmed, and the per-contact disable
   you need is confirmed to exist) and the **commercial-model's "operators have zero
   control and very limited knowledge of user activity"** tenet, which a message-holding,
   per-queue-scheduling fork directly violates. There is also a real **conflict with the
   planned member-send-limit `wait`/hold-next throttle**, which fights your scheduler for
   control of inter-message timing.

4. **New hard ceilings and mechanics v1 omitted:** a **21-day server message TTL** (a
   second ceiling on "just delay it," alongside QUOTA); the **QUOTA capacity is a
   compile-time constant (128), not an `.ini` setting**; **service-session subscriptions**
   (`SUBS`, one TLS session subscribing many queues) break v1's per-connection `SUB`
   assumption; **queue rotation** means a "sensitive queue" flag isn't stable; and the
   **stock sending proxy forwards immediately under a hard timeout** — holding is not a
   small patch to it but a change of its semantics. See §3 and §5.

Everything in v1 that was verifiable is **confirmed accurate** against the pinned source
(PRXY at `Protocol.hs:576`, QUOTA/marker at `simplex-messaging.md:758`/`:1037`, the
push/ACK model, the mix-node quote, the receipt leak). The corrections below are
refinements and additions, not reversals.

---

## 1. Core idea in one line (unchanged)

> The server emits a **predetermined, variable, human-looking** stream of messages on a
> sensitive queue; **real traffic only ever rides slots that stream already allows**, so
> the observable pattern is identical whether or not real content exists — and it costs
> cover bandwidth **only on marked queues, only at the human-shaped rate**, not flat
> constant rate for everyone.

Constant-rate cover is the sledgehammer (flat = its own fingerprint, expensive). Full
mixing is crowd-dependent (useless without a crowd). This sits between: **self-generated
cover, shaped like a person, scoped to sensitive queues, with real traffic riding the
schedule.** In SimpleX's own vocabulary, this is **scheduled, variable noise traffic with
real-message multiplexing** — the project named the primitive (§2.1); this design specifies
the *shape* and the *control loop* it never did.

---

## 2. What SimpleX already says, plans, or ships (the new grounding)

This section is the answer to "is anything like this planned, and how detailed." Detail
levels: **named** (threat-model word, no design) ▸ **roadmap** (listed/recommended,
no design) ▸ **sketch** (options enumerated) ▸ **detailed-design** (RFC with types/flow) ▸
**shipped**.

### 2.1 "Noise traffic" — the project's own word for dummy cover ▸ named, NOT implemented
SimpleX's threat model treats dummy traffic as a real concept:
- Whitepaper lists it as an intended **agent-level operation**: "Rotating queues
  periodically… / **Noise traffic**" (`simplexmq/protocol/overview-tjr.md:219`), and as a
  mitigation a router-distrusting agent "supports": "rotating the queues…, **noise
  traffic**, supporting overlay networks such as Tor…" (`overview-tjr.md:153`), and against
  passive observers: "Techniques such as **noise traffic, traffic mixing (incurring
  latency)**…" (`overview-tjr.md:147`).
- The formal threat model bakes in indistinguishability: a router "cannot **distinguish
  noise messages from regular messages except via timing regularities**"
  (`simplexmq/protocol/security.md:113`, repeated `:149`); a router may see a queue's
  message count "although some may be **noise or not content messages**" (`security.md:91`).

So the property this whole design rests on — *a dummy and a real `MSG` are the same object
on the wire, and only timing distinguishes them* — is **stated by SimpleX itself**. But a
code search of both repos finds **no implementation** of noise traffic. It is a threat-model promise, not shipped behavior. **Implication:** frame the fork as *implementing SimpleX's own "noise traffic," with a human-shaped schedule and real-message multiplexing added* — it inherits the project's indistinguishability argument rather than re-deriving it.

### 2.2 Opportunistic mixing — shipped but explicitly not relied upon ▸ shipped (hedged)
"When enough traffic is transiting a router simultaneously, the router acts as a
low-latency mix node. **We can't rely on this behavior to make a security claim**, but we
have engineered to take advantage of it when we can." (`overview-tjr.md:170`, verified
verbatim.) v5.8 private message routing additionally **mixes multiple senders into one
relay TLS session** (`simplexmq/rfcs/done/2023-09-12-second-relays.md:120`) — but the same
RFC concedes "even mixing all messages to one proxy connection does not provide protection
against traffic correlation by time… it requires adding delays" (`:247`). This is the gap
self-cover fills (§4).

### 2.3 Randomized delivery latency — roadmap + audit recommendation ▸ roadmap, not designed
- `README.md` roadmap item: "Message **\"mixing\"** — adding latency to message delivery,
  to protect against traffic correlation by message time."
- The 2024 Trail of Bits design review **recommended** "optional randomized latency to
  message delivery… we consider adding it in the future"
  (`blog/20241014-…v6-1….md`). So *delay-for-correlation* is acknowledged and blessed; only
  *cover* and *human-shaping* are novel here.

### 2.4 `MessageSchedule` — server-held delayed delivery, already designed ▸ detailed-design
The super-peers RFC defines exactly your hold/release primitive, with the same motivation:
```haskell
data MessageSchedule = MessageSchedule
  { deliverAt :: Maybe UTCTime  -- default: when received by super-peer
  , minDelay  :: Maybe Int      -- seconds
  , maxDelay  :: Maybe Int }    -- "to deliver 20-40s after receipt,
                                 --  to complicate traffic correlation: {20,40}"
```
(`docs/rfcs/2024-04-01-super-peers-2.md:217-230`.) **This is the strongest hook in the
corpus** — reuse its shape. Caveat: it lives in the **super-peer/group** layer (a relay
forwarding to members), **not** the SMP server. So it validates the *concept* of
server-side scheduled delay-for-correlation as project-sanctioned, but doesn't give you SMP
code.

### 2.5 The sending proxy is named as a delayed-delivery extension point ▸ named
v5.8's forwarding-relay design "can also be extended to support **delayed delivery** and
other functions" (`blog/20240604-…v5.8….md:60`). This is the project itself pointing at the
`PRXY`/`ProxyService` path (v1 §2.4) as the place to add hold/release. **But** the stock
proxy is a stateless pass-through that "MUST process commands under a reasonable timeout or
the client would halt" and forwards immediately (`simplexmq/src/.../Server.hs:1411-1440`).
So "proxy holds the message" is a **semantic change** to the proxy, not a tweak.

### 2.6 Channels-forwarding store-and-forward — real server-side holding ▸ detailed-design
Channels introduce **persistent, resumable, batched** store-and-forward with a
`forwarding_jobs` table, holding messages until `forward_complete`
(`docs/rfcs/2025-08-11-channels-forwarding.md`). This is genuine server-side message
holding with batched fan-out — **a natural injection point for noise padding or held/delayed
reals** if the cover scheme is built for channels/relays rather than 1:1 SMP queues.

### 2.7 Constant-time auth as a timing defense already in code (context, not cover)
The server runs `dummyVerifyCmd`/`dummyKeyEd25519` to do **constant-time verification even
for non-existent queues, to mitigate timing attacks on `ERR AUTH`** (`Server.hs`,
`simplex-messaging.md`). Not traffic cover, but shows the codebase already reasons about
timing side-channels — useful precedent when arguing a timing-cover fork is "in spirit."

---

## 3. Components (revised)

### 3.1 Per-queue "sensitive" marking + cooperative subscription
Unchanged intent (mark queues sensitive, negotiate cover only for those, zero overhead
elsewhere). **Three new mechanics a fork must handle:**
- **Service sessions.** A single TLS session can now subscribe *many* queues at once via
  `SUBS`/`RecipientService`/`SOK serviceId` (`Protocol.hs:326-344,551,573`). v1's analysis
  assumed per-connection `SUB`; cover/scheduling logic must work over service-batched
  subscriptions, and the per-queue silhouette must survive being multiplexed onto a shared
  service session.
- **Queue rotation.** Queues rotate (agent `RcvSwitch`/`switchConnection`), so a "sensitive
  queue id" is not stable — the **sensitive flag must be carried across rotation**, or cover
  silently lapses when the queue switches.
- **Short links & SKEY.** Modern connection setup uses short links (`LSET`/`LKEY`/`LGET`,
  `shortLinksSMPClientVersion=4`) and sender-secured queues (`SKEY`); a fork touching queue
  creation/securing must not break these paths.

### 3.2 The schedule = the silhouette (variable, not constant) — unchanged
Bursty, diurnal, gappy, from the lossy parametric human-messaging model. Shared via seed
(server-derivable) or client-pushed (§3.6). **New ceiling:** the gap model collides with
both QUOTA *and* the 21-day TTL (§5.9) — a multi-day programmed silence while reals arrive
will fill the queue and/or expire messages.

### 3.3 Real-fits-in-dummy (token bucket at the server) — unchanged
At each slot, emit one message: a real one if waiting and permitted, else a dummy
(=noise message, §2.1). Reals above slot-rate queue (leaky bucket). Observable shape never
changes with real existence. This is the multiplexing layer SimpleX's "noise traffic"
concept never specified.

### 3.4 Client-(semi-)controlled delayed delivery to sensitive contacts — refined
The server, as sending proxy, holds and releases on schedule. **Hook confirmed and
blessed** (§2.5) but the stock proxy forwards immediately under a timeout (§2.5), so this is
a new stateful proxy mode, not a small patch. Reuse the `MessageSchedule` shape from §2.4
for the hold parameters. ⚠️ Still bounded by §5.9 (QUOTA + TTL).

### 3.5 Urgency override (deliberate, costed) — unchanged
Per-message urgency bypasses the hold. Out-of-schedule emission is an observable anomaly.
Mitigations: snap to nearest slot; pre-provisioned denser "urgent schedule"; or accept the
leak. User chooses when to spend cover for speed.

### 3.6 Two directions of control (server-conducted vs client-authored) — unchanged
(a) Server-conducted: instructions ride inside the dummies' encrypted bodies; server cues a
thin client (sidesteps the mobile-timer problem *while connected*). (b) Client-authored:
client computes the schedule from its own model and hands it to the server to execute
(keeps the behavioral fingerprint client-side). (a) suits mobile; (b) suits users who
don't want the server authoring their profile.

---

## 4. Why full mixing does **not** make this obsolete (tightened, same conclusion)

Mixing's anonymity = anonymity-set size = concurrent cross-user traffic — exactly what a
niche/personal/targeted server lacks.

- **Mixing collapses at low traffic; self-cover doesn't.** A 1–2-message window gives ~zero
  anonymity. Confirmed by SimpleX itself: mixing is opportunistic and "we can't rely on
  this… to make a security claim" (`overview-tjr.md:170`). Self-generated noise is
  independent of other users — **it works at user-count = 1.** You are your own anonymity
  set.
- **They compose (floor + crowd-discount).** Use the real cross-user pool when the set is
  large; top up with self-noise when it isn't. The noise budget shrinks as genuine cross
  traffic grows. Self-cover is the floor; mixing is a discount on top.
- **It drops the user-count threshold for a server to be private at all.** A single
  sensitive user gets protection from day one — small/personal/family/single-user servers
  become viable for privacy, the inverse of mixing's "needs a crowd."
- **The targeted-user carve-out is SimpleX's own admission this regime is undefended.**
  "The protocol does **not** protect against attacks targeted at particular users with
  known identities — e.g., if the attacker wants to prove that two known users are
  communicating, they can achieve it by observing their local traffic"
  (`overview-tjr.md:172`). That *is* the threat this design targets.
- **When mixing would dominate (be honest):** only when a persistently large,
  well-distributed 24/7 anonymity set exists, you accept depending on strangers' presence,
  you trust the mix is honest (a malicious mix just doesn't shuffle — same trust as a cover
  server, so not a differentiator), and you accept mix latency. That's the high-traffic
  public-server case — not this thread's.

---

## 5. Concerns (the sharp ones — expanded)

### 5.1 🔴 Delivery receipts are a fatal tell unless handled — CONFIRMED both ways
A dummy is discarded silently; a **real** message makes the recipient's stock client
**auto-send a delivery receipt** — an observable downstream event a dummy never produces.
Verified: receipts are generated in the **chat core** (`simplex-chat/.../Library/
Subscriber.hs:534-540`, `checkSendRcpt`), **default ON for new profiles**
(`sendRcptsContacts`), and **disableable per-contact** via `SetSendReceipts`
(`Commands.hs:1910`) — so the mitigation you need exists. The threat model documents the
leak: a contact can "identify that and when a user is using SimpleX, **in case user has
delivery receipts enabled, or based on other automated client responses**"
(`docs/protocol/simplex-chat.md:307`, `:327`). Note the generalization: **any** automated
client response (not just receipts) is a real-only tell — see §5.3. **The scheme must
disable or itself schedule receipts (and all auto-responses) for sensitive contacts.**

### 5.2 🔴 The contact's side is still uncovered (existence, not just timing) — CONFIRMED
Your cover protects *your* queues. The **recipient's SMP server always sees the recipient's
queue activate** once per real message — "know how many messages are sent via the queue"
(`simplexmq/protocol/security.md:91`) — regardless of any sender-side cover. So delaying at
your proxy hides *when* the contact receives, not *how many / whether*. Dummy cover toward a
stock contact is impossible unilaterally (their client would choke on dummies). Full edge
protection is **bilateral**: needs the contact's forked client (discards dummies) or the
contact's queue on a forked server (injects noise). This design cleanly solves *your* side
and the *timing* of the edge, not the *existence* of the contact's receive events.

### 5.3 🟠 Real and dummy must be byte/behavior-indistinguishable end-to-end
On the wire, fixed 16 KB padding already makes `MSG`s uniform (`Transport.hs:152
smpBlockSize=16384`, `Crypto.hs:1082 pad`). But indistinguishability must hold past the
wire: same size, same `ACK` pattern, same retry, and **no real-only side effects** —
receipts (§5.1), notifications, file-fetch follow-ups, mention/auto-reply behavior. SimpleX's
own framing ("or based on other automated client responses") makes this explicit.

### 5.4 🟠 Urgency override leaks by construction
An out-of-schedule emission says "something happened around now." Fine against a law-bound
adversary; a burst is a burst against a targeted global one. Snap-to-slot and pre-provisioned
urgent schedules reduce, don't erase.

### 5.5 🟠 Wire-adversary vs server-compromise are different threats (nuance added)
Real-vs-dummy is decided **inside the server, in memory.** A **wire/network adversary**
watching *your* side sees only the content-independent pattern → defended. A **compromise
of your forked server** reveals which slots were real and the sensitive-queue list → not
defended; the server knows the secret it hides. **Nuance v1's §5 table missed:** SimpleX's
threat model concedes that a passive adversary monitoring a *set* of senders and recipients
can already "learn when messages are sent and received" and correlate, "frustrated by the
number of users" (`security.md:75-77`). Your cover defeats a wire adversary who **cannot see
the contact's recipient server**; it does **not** defeat an adversary who watches **both**
endpoints' servers (the recipient's server sees the contact's side per §5.2). So "defeats
wire adversary" is true only for the *single-side-monitoring* adversary — see corrected
table in §7.

### 5.6 🟠 Opt-in concentrates a meta-signal ("this user uses cover")
Per-queue cover marks the user as privacy-seeking *to the server*, and possibly to a wire
observer if the pattern is distinguishable from organic. The human-shaped (lossy-model)
schedule blunts wire distinguishability. To blunt the server-side meta-signal, apply
**light plausible noise to many users by default** — which is *exactly* the "agent-level
noise traffic" SimpleX already says it intends (§2.1), so default-on light noise is both the
meta-anonymity fix and the project-aligned framing. Pure opt-in trades bandwidth for a
meta-anonymity cost.

### 5.7 🟡 Mobile: server-conducted cueing only works while connected
Dummies can cue a connected client but **can't reach a Dozing phone** (wake-path limit).
The notification server is a **separate address** from the message queue and only relays a
"message arrived" signal; it already **caps hidden notifications at ~2-3/hour** (collapsing
to a generic "new message" above that, per `blog/20220404-…md`) — a small built-in
normalization, but not cover. Verified: there is **no out-of-box 24/7 same-account VPS
path** — "use from desktop" is always phone-tethered (`leodocs/use-from-desktop-ux.md:28-32,
181-191`). So the sensitive client ideally runs always-connected (desktop/VPS as a separate
identity), or you accept reduced protection while the phone sleeps. A forked **notification**
server that batches/normalizes wake-ups is a necessary companion fork — and `NMsgMeta` is
only `{msgId, msgTs}` E2E-encrypted to the recipient (`Protocol.hs:869`), which bounds what
such a fork can normalize without breaking decryption.

### 5.8 🟡 Schedule knowledge is fine; schedule *violation* is the leak
Adversary knowing the schedule doesn't break it (real fits inside, indistinguishable within
a slot). What breaks it: real traffic *outside* the schedule (urgency §5.4) or a schedule
too thin for real demand (overflow → latency or a visible raise). Provision the schedule's
peak to the contact's plausible peak (per-relationship silhouette).

### 5.9 🔴 The "just delay it" ceilings: QUOTA **and** TTL
Two server-side limits bound the *delay* half of the design.
- **QUOTA (capacity ÷ inbound rate).** Queues have fixed capacity (`defaultMsgQueueQuota =
  128`, `Server/Env/STM.hs:256`); when a recipient stops draining and the queue fills,
  **senders get `ERR QUOTA`** and, after drain, a special **`msgQuotaExceeded` marker** is
  delivered (`simplex-messaging.md:758`, `:1037`). So holding/throttling *retrieval* until
  the queue overflows makes **anyone messaging you learn you're not draining** — the exact
  "is this user delaying/active" signal you're hiding — and the marker is a real-only event
  (§5.3). **Correction to v1:** the spec says capacity is "defined by the server
  configuration," but in the pinned code it's a **compile-time constant, not an `.ini`
  option** — raising it for sensitive queues is a recompile, not a config edit (and doesn't
  help against the contact's stock server).
- **Message TTL (NEW — v1 omitted).** The server expires stored messages after
  `defaultMessageExpiration` = **21 days** (`defMsgExpirationDays=21`, check every 2h, plus
  expire-on-start/on-send; `Server/Env/STM.hs:213-221`, `Main.hs:551-557`). A held/delayed
  message also can't outlive the queue's TTL. Disappearing-message TTLs are **client-side
  only** with no server TTL to lean on, so long holds risk silently dropping content.
- **Mitigation:** decouple "server drains the queue" from "client surfaces to the user" —
  drain often (stay under QUOTA and TTL) but *display* on the slow human cadence. The cover
  lives in *delivery/notification* timing, not in letting the queue back up.

### 5.10 🟠 Conflict with the planned member-send-limit throttle (NEW)
The member-send-limits RFC explores receive-side throttling via "**ACK with parameter
`wait` — server would wait before sending next message**" and "signal agent to hold on next
message" (`docs/rfcs/2025-02-17-member-send-limits.md`, sketch). That is the **same lever**
your cover scheduler uses to pace delivery. If a rate-limiter and the cover-scheduler both
try to control inter-`MSG` timing, they fight — and the limiter's `wait` can distort
(and thereby leak through) the human-shaped silhouette. A fork must own one timing
authority, not two.

### 5.11 🟠 Server-side BLOCK interaction (NEW, mild)
Moderation adds a control-port `CPBlock`/`BLOCKED {reason,notice}` on queues/files/links
(`Server/Control.hs:29`, `Protocol.hs:1473,1594`). Two frictions: a fork that keeps emitting
cover toward a blocked queue is operator-visibly inconsistent, and the BLOCKED marker is a
distinguishable real-only event (§5.3). Different axis from cover, but a fork author touches
the same server.

---

## 6. Breaking details, inconsistencies, and contradictions (direct answer)

**A. Against the project's *direction/policy* (the serious one):**
- 🔴 **Commercial-model contradiction.** The commercial-model RFC's core tenet is that
  operators have "**very limited knowledge of users activity**" and "**zero control**," with
  extreme portability across 4-6 interchangeable operators
  (`docs/rfcs/2024-04-26-commercial-model.md`, detailed-design-concept). A fork that
  **holds messages, schedules per-queue, and learns which slots are real** is *exactly* the
  operator-visibility and statefulness the model rejects. This design philosophically pulls
  **against** SimpleX's "dumb, interchangeable, low-knowledge relay" trajectory. It's
  coherent *for a self-hosted personal server* (you trust yourself), but it does **not**
  generalize to the preset-operator network, and it should be pitched as a self-host /
  niche-operator tool, not a network-wide feature.

**B. Against shipped behavior (must-handle):**
- 🔴 **Delivery receipts** (§5.1) — fatal real-only tell; mitigation (per-contact disable)
  confirmed to exist.
- 🔴 **Contact's recipient server sees their side** (§5.2) — bilateral problem, irreducible
  unilaterally.
- 🔴 **QUOTA + 21-day TTL ceilings** (§5.9) — hard bounds on delay; "raise capacity" is a
  recompile.
- 🟠 **member-send-limit `wait` throttle** (§5.10) — competing timing authority.
- 🟠 **Stateless proxy under hard timeout** (§2.5) — holding is a semantic change, not a
  patch.
- 🟠 **Service sessions / rotation / short links / SKEY** (§3.1) — v1's per-connection-`SUB`,
  stable-queue-id model is outdated; the fork must handle batched service subscriptions and
  carry the sensitive flag across rotations.

**C. Internal to v1 (corrections):**
- 🟡 **§5 table overclaim:** "Defeats wire adversary ✅" is true only for an adversary
  monitoring *one* side; a both-sides-monitoring passive adversary still correlates via the
  recipient's server (§5.5). Corrected in §7.
- 🟡 **Stale path:** the mix-node quote is in `protocol/overview-tjr.md:170`, not
  `rfcs/overview-tjr.md` (quote itself is verbatim and correct).
- 🟡 **"server configuration" wording** for queue capacity is true per spec but misleading
  per code (compile-time constant) — §5.9.

**D. Is the *idea* contradicted by SimpleX's own plans? — No; it's mostly unbuilt-but-named
(§2).** "Noise traffic" is **named** in the threat model with **zero implementation and no
design**. Delayed delivery is **detailed-design** but in the super-peer layer
(`MessageSchedule`) and **named** as a proxy extension. Randomized latency is **roadmap +
audit-recommended**. The *specific* contribution here — **per-queue, variable/human-shaped,
scheduled cover with real-fits-in-dummy multiplexing and an urgency override** — is **not
planned anywhere**. So: the primitive is sanctioned, the *system* is greenfield.

---

## 7. Feedback & ideas for planning the server fork

1. **Pitch it as "implementing SimpleX's own noise traffic," not as a new feature.** It
   inherits the project's indistinguishability argument (§2.1) and its own admission that
   the targeted-known-user case is undefended (`overview-tjr.md:172`). This framing also
   helps any upstream conversation.
2. **Reuse the `MessageSchedule {deliverAt,minDelay,maxDelay}` shape** (§2.4) for hold/release
   parameters — it's already the project's vocabulary for delay-for-correlation, so client
   and server speak a familiar type.
3. **Build on channels-forwarding store-and-forward, not the 1:1 SMP proxy, if you can.**
   The `forwarding_jobs` hold-until-complete machinery (§2.6) is real server-side holding
   with batched fan-out — a far better injection point for noise/delay than retrofitting the
   stateless, timeout-bound `PRXY` path. For 1:1, the proxy hold is a genuine semantic change
   (§2.5).
4. **Decouple "drain the queue" from "surface to the user."** This is the key trick that
   dodges both §5.9 ceilings: pull from the SMP queue promptly (stay under QUOTA and the
   21-day TTL), buffer client-side, and *present/notify* on the human cadence. The cover
   lives in delivery/notification timing, never in letting the receive queue back up.
5. **Default light noise to many users; opt-in for dense cover.** §5.6 — universal light
   noise blunts the "this user uses cover" meta-signal *and* matches the agent-level
   noise-traffic SimpleX already intends. Reserve the dense, scoped, human-shaped schedule
   for explicitly sensitive queues.
6. **Own a single timing authority.** Decide up front that the cover-scheduler is the one
   thing pacing inter-`MSG` timing; do not also enable the member-send-limit `wait` throttle
   on sensitive queues (§5.10).
7. **Carry "sensitive" across rotation and onto service sessions** (§3.1). A flag tied to a
   queue id silently lapses on rotation; a per-contact/per-relationship flag that follows
   the switch is safer. Verify the silhouette survives `SUBS` multiplexing.
8. **Suppress *all* auto-responses for sensitive contacts, not just receipts** (§5.3) —
   audit notifications, auto-replies, mention pings, file-fetch follow-ups. SimpleX's own
   wording ("or based on other automated client responses") is the checklist.
9. **Plan the companion notification fork early** (§5.7). On mobile the message-path cover
   doesn't reach a Dozing phone; the notif server is a separate address with its own ~2-3/hr
   cap. A normalizing notif fork is necessary for any mobile story, and `NMsgMeta` being
   E2E-encrypted to the recipient bounds what it can rewrite.
10. **Minimize what the fork persists** (§5.5). Schedule in memory, no real/dummy logs, no
    persisted sensitive-queue list — the fork is the one place that both produces and could
    betray the secret. Treat host compromise as game-over and design for self-hosting.
11. **Respect (or consciously decide about) BLOCK** (§5.11) — don't emit cover toward
    blocked queues/links; keep the fork's behavior consistent with the operator's moderation
    state to avoid an operator-visible anomaly.
12. **Stay inside the TTL budget** (§5.9). Any hold longer than days must reckon with the
    21-day server expiry and client-side disappearing-message TTLs that have no server-side
    enforcement to lean on.

---

## 8. What this buys vs the alternatives (corrected table)

| Property | Constant-rate cover | Full mixing | **This (variable cooperative self-cover / "noise traffic")** |
|---|---|---|---|
| Works at 1 user / quiet server | ✅ (flat & costly) | ❌ (needs a crowd) | ✅ |
| Bandwidth cost | High, always-on, all queues | Low (crowd pays) | **Scoped to sensitive queues, human-rate** |
| Looks like an organic channel | ❌ (flat is a fingerprint) | n/a | ✅ (lossy-model shaped, gappy) |
| Hides *your* send timing | ✅ | ✅ (if pool large) | ✅ (server-held + slotted) |
| Hides *your* receive timing | ✅ | ✅ (if pool large) | ✅ (drain≠surface; bounded by QUOTA+TTL) |
| Hides the contact's side | only if contact also covered | only if both in pool | ❌ unilaterally (bilateral needed) |
| Defeats **single-side** wire adversary | ✅ | ✅ | ✅ |
| Defeats **both-endpoints** passive adversary | ❌ (recipient server still sees their side) | ✅ (if pool large) | ❌ (recipient server sees contact's side) |
| Defeats server compromise | ❌ | ❌ | ❌ |
| Low-latency option | ❌ | ❌ | ✅ (urgency, at a cover cost) |
| Aligns with SimpleX's stated design | partial | ✅ (roadmap, opportunistic) | ✅ ("noise traffic" is named; delay is roadmap) — but ⚠️ conflicts with commercial-model operator-zero-knowledge |

---

## 9. Bottom line

A forked server doing **variable, opt-in, schedule-orchestrated cover** remains the right
tool for this thread's regime — **few sensitive contacts, low volume, delay-tolerant,
quiet/personal server** — and v2's verification *strengthens* that case: SimpleX **names
this exact primitive ("noise traffic"), concedes the targeted-known-user case is
undefended, and has already designed server-side delay-for-correlation
(`MessageSchedule`)** — it simply never built any of it, and never specified the
human-shaped, real-multiplexing *system* this proposes. The work is therefore "finish what
the threat model promised," not "fight the architecture."

The irreducible residuals are unchanged and now fully grounded: the **contact's uncovered
receive existence** (bilateral cooperation needed; the recipient's own server always sees
it), **delivery receipts and all other auto-responses** (must be suppressed/scheduled —
the per-contact toggle exists), the **QUOTA + 21-day TTL delay ceilings** (drain ≠ surface),
and **trust in your own server** (which now knows the secret it hides). The two genuinely
*new* cautions for a planner: this design **competes with the planned member-send-limit
timing throttle**, and it **runs against the commercial-model's "zero-knowledge,
interchangeable operator" direction** — so it belongs as a **self-hosted / niche-operator**
capability, not a network-wide one.
