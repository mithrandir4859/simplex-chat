# Timing-correlation article — assumption audit

> Adversarial review of the "Defending a Few Sensitive Contacts Against Timing
> Correlation" article, checking its baked-in protocol assumptions against the actual
> SimpleX code. Focus per request: **truly breaking** problems (ones that invalidate a
> mechanism or its threat model), not cosmetic "off by a detail but fixable in spirit."

## 0. Scope and verification

- **UPDATE — now verified directly against `simplexmq` source** (cloned at the pinned
  commit `b981dcb7`, the tag in `cabal.project:24`). The first draft of this audit
  inferred SMP internals indirectly; the checkout confirmed the big claim (push vs poll)
  **and corrected two of my own findings** (B2 and B3 below — I had been too harsh on the
  article). Citations now point into `simplexmq` (`protocol/simplex-messaging.md`,
  `src/Simplex/Messaging/Protocol.hs`, `Transport.hs`).
- Confirmed facts: `SUB` (subscribe/push) is the main delivery path; `GET` retrieves
  **one message without subscribing** and is documented as "used when processing push
  notifications" (`simplex-messaging.md` Get-message section), and **a client MUST NOT
  use `SUB` and `GET` on the same queue in one connection**; every transport block is
  **padded to a fixed 16384 bytes** (`Transport.hs:153`, `C.pad`); a delivered message is
  followed by an **`ACK`** so the server deletes it (`simplex-messaging.md:254`); the
  **sender proxy/relay exists** (`PRXY`, `ProxyService`, `sendingProxySMPVersion`,
  `Protocol.hs:576`); message **mixing/latency is not implemented or relied upon**
  (`overview-tjr.md:170` — opportunistic only "when enough traffic is transiting…", "we
  can't rely on this").

## 1. Verdict up front

**The strategic thesis is sound; the single real architectural error is the
*polling* framing (B1). The article's instincts about the presence leak and decoys are
*more correct than my first draft credited* — the checkout downgraded my B2/B3 from
"breaking" to "right idea, wrong mechanism / overstated."**

- Sound and largely architecture-independent: *decouple observable timing from content*;
  *cover must be manufactured because a low-volume user has none*; *joined-group cover is
  cancellable*; *conserved weirdness / relocate-don't-eliminate*; *lossy parametric
  timing model beats replay*; *everything costs latency or bandwidth*; *the targeted
  global case is structurally undefendable from one client*. These survive scrutiny.
- The one genuinely breaking architectural mismatch (B1): the receive path is
  **server-push over persistent subscriptions (`SUB`)**, not client polling. The article's
  "poll all queues on a schedule" is `GET`-mode, which exists but is the
  notification-fetch command and is mutually exclusive with `SUB` on a queue — so
  scheduling retrieval means *abandoning subscriptions for poll-only*, a bigger and more
  anomalous change than "stock protocol used creatively," and one that must be stated.
- Corrected after checkout: the **presence leak is real on the live path** (via the
  `ACK` after each `MSG`, B2) and **decoys do provide which-queue + presence cover**
  against a wire observer because everything is padded to 16 KB and multiplexed in one TLS
  (B3). The hard residual is the **timing** correlation (B4), which scheduling/delay — not
  decoys alone — must sever.

---

## 2. The receive-path assumptions, checked against source
_(B1 genuinely breaking; B2–B3 corrected after checkout — my first draft was too harsh; B4–B5 real residuals.)_

### B1. 🔴 The receive path is push/subscribe, not poll — so "scheduled retrieval of decoy queues" is not "the stock protocol used creatively"

**Article assumes** (3.2/3.3, and all of 4–6): the client *checks*/*polls* queues; you
"poll all of them (S plus decoys) on each scheduled retrieval in randomized order"; you
control *when you retrieve*; retrieval is the thing you schedule.

**Reality:** the stock SMP client opens **persistent TLS connections** to servers,
issues **`SUB`** to subscribe to its queues, and the **server pushes `MSG`** the instant
a message arrives; the client **`ACK`s** and the server deletes (`Subscriber.hs:128`
"without ACK the message delivery will be stuck"; subscription status events
`CEvtSubscriptionStatus`/`CEvtSubscriptionEnd`, `Subscriber.hs:150,364`). This is the
same persistent-push mechanism that makes SimpleX's "instant notifications" work without
Google/Apple push. **There is no scheduled "check" in the normal client.**

**Why it breaks, not bends:**
- To get *schedulable* retrieval you must **abandon subscriptions entirely and poll**
  (SMP does have a one-off `GET`, so poll-mode is *possible* — but this is a
  `simplexmq`-level detail I couldn't open here). That is **not** "stock protocol used
  creatively"; it is **replacing the client's entire transport behaviour**, and a client
  that *never subscribes and instead `GET`-polls on a timer* is itself a glaring,
  rare-on-the-network anomaly — exactly the "weirdness" the article elsewhere says to
  avoid putting on your primary identity.
- **Critically, if you do *not* disable push, the decoys are pointless:** the server
  pushes the real message from S the instant it arrives, over the already-open
  connection, and the correlatable event happens *at arrival time regardless of your
  decoy-polling schedule.* So "poll decoys on a schedule" only severs receive-timing
  **if you first turn off subscriptions** — a load-bearing prerequisite the article
  never states.
- The article's "you learn of a real message on the next tick, not instantly" is only
  true in poll-mode. In the stock (push) client you learn instantly, and so does anyone
  correlating.

This is the deepest issue: the entire receive-side construction is specified against an
architecture SimpleX doesn't use, and the migration to the architecture it *needs*
(poll-only) is both unacknowledged and self-anomalizing.

### B2. 🟢 CORRECTED (was 🔴): the presence leak *does* exist on the main push path — via the `ACK`, not a "check"

**My first-draft claim was wrong** and the checkout corrects it. I had said the
"packet-count" leak lived only on the notification/`GET` path and the main push path had
"no per-check leak." True that there is no *check* on the push path — but a **message's
presence is still observable on the live connection**, by a different mechanism:

- A delivered message is a **server→client `MSG` block followed by a client→server `ACK`
  block** (`simplex-messaging.md:254` — "she acknowledges… so the server can delete the
  message and deliver the next"). No message → no such pair.
- Every block is padded to a fixed **16384 bytes** (`Transport.hs:153`), so block *sizes*
  leak nothing — but the **existence and timing of the `MSG`+`ACK` pair** is observable by
  counting/timing blocks. So "a message was delivered" leaks on the main path too.

So the article's core worry (presence is observable) is **correct on the live path**, and
my dismissal of it was the error. The article mis-attributed the *mechanism* (it framed it
as a poll/packet-count thing on the notification path; it's actually the `ACK` follow-up
on the push path), but the leak it's defending against is real where it matters. Net:
**downgrade from "breaking" to "the article is right, the mechanism differs."**

### B3. 🟡 CORRECTED (was 🔴): decoys *do* give cover against a wire observer — they hide *which* queue; the real residual is timing, not "decoys are useless"

**Also too harsh in the first draft.** I claimed decoys "add essentially zero cover
against a wire observer." The padding + multiplexing facts overturn that:

- All your queues ride **one TLS connection**, and the `MSG`/`ACK` blocks are **padded to
  16 KB with the queue ID encrypted inside** (`Transport.hs:153`). So a wire observer sees
  `MSG`+`ACK` pairs but **cannot tell which queue** they belong to. Decoy queues that you
  keep flowing therefore **do** provide genuine "which-queue" cover *and* presence cover
  (a real pair is one among several indistinguishable pairs).
- What decoys **do not** fix by themselves is the **timing correlation**: the contact
  sends → a `MSG`+`ACK` pair appears on your connection shortly after. If your decoy pairs
  are sparse, the one correlated-in-time with the contact's send is the giveaway. Cover
  requires the pairs to be **dense/scheduled enough** (or the real delivery delayed to a
  slot) that the contact-correlated pair isn't singled out — which is the
  schedule/delay machinery, not the decoys alone.

So decoys are a **valid** building block against both the wire observer (which-queue +
presence) and the server operator (which-queue); the genuinely hard residual is
**severing the send→delivery *timing* correlation**, which is what scheduling/delay (and
the forked-server design) is for. The adversary-conflation criticism stands in spirit
(the article should still distinguish wire-observer vs server-operator visibility, since
what each sees differs), but my "zero cover" verdict was wrong.

### B4. 🟠→🔴 The send-side is declared "easy/solved," but scheduling your sends does not sever the scheduled-send → contact's-instant-receive correlation, and the contact (stock client, push) leaks their side unconditionally

**Article assumes** (3.1): scheduling your emissions makes the send side
"content-independent… Good, but it is the easy half," implying the send direction is
handled.

**Reality / residual:** your real message still rides a *scheduled tick*, but the moment
it's sent it lands in the contact's receive queue and **their stock client is
push-subscribed**, so **their queue delivers essentially immediately** — the
send→their-receive delay is still tight and real. The defense therefore reduces entirely
to **cover density/shape**: every one of the contact's (uncovered, reactive) receive
events must be plausibly preceded by one of your scheduled ticks, *and* most of your
ticks must precede nothing — i.e. your cover rate must be high enough, at the right
times, that the contact's real receives are statistically indistinguishable from "a tick
happened to precede a tick." The contact runs stock software and **cannot be given
cover**, so *their* side of the edge is always observable; you are only fuzzing *your*
side. Calling the send side "easy" understates that its safety is a quantitative
property of cover rate vs. the contact's arrival rate (which is exactly the Section-4
silhouette analysis — so the article contradicts its own "easy" framing two sections
later).

### B5. 🔴 Mobile reality: the protected user's own client is (realistically) a phone, where the OS forbids the always-on, freely-scheduled retrieval the scheme assumes

**Article assumes** the forked client can emit/retrieve on an arbitrary schedule
24/7 (poll-mode in B1, liveness beacons in §7, decoy refill loop in 3.3).

**Reality:** the sensitive *user's* device is almost certainly a phone (the bot is on a
VPS — that part is fine). On Android, **Doze and background-execution limits** throttle
exactly this kind of timer-driven background networking (established at length in this
repo's own remote-control analysis); on iOS, arbitrary background polling is essentially
impossible. A phone that must wake on a precise schedule to `GET`-poll decoys and emit
beacons is fighting the OS, and the result is *jittered, OS-shaped* timing — which (a)
degrades the cover and (b) is itself another anomaly. The scheme implicitly assumes a
machine you fully control 24/7 (a desktop/VPS), which is **not** the typical threatened
user's messaging device. This isn't fatal for the VPS-bot half, but it is breaking for
the "forked client on the user's phone" half, which the article treats as unproblematic.

---

## 3. Meaningful but in-spirit fixable

### F1. 🟡 "Self-messaging A→B both yours" ≠ the built-in note-to-self
SimpleX's "note to self" / local notes are **local-only — no network traffic**, so they
generate **zero cover**. To get wire-visible self-traffic you must stand up **two real
connected profiles/queues** (go through the connection handshake, queues on real
servers). Doable, and in-spirit what the article means, but "make queues whose contact
is yourself… nothing but the stock protocol" understates that you're provisioning real
second-identity infrastructure, not using note-to-self.

### F2. 🟡 "All padded to fixed block sizes so even length leaks nothing" — true for messages, not for files
SMP messages are padded to a **fixed transport block** (so message length is hidden —
this part is correct and is reflected in the size constants around `Protocol.hs:889`).
But **file transfer (XFTP)** chunks into a small set of fixed **size classes**, so large
files leak a coarse size category. Minor for the article's chat-timing focus, but the
absolute "length leaks nothing" is too strong.

### F3. 🟢 Server-primitive epilogue is well-aimed (credit) — with one correction
The proposed primitives ("return a response shaped like N messages regardless of
contents"; "suppress until I ask") are the right shape, and the "conserved weirdness must
be made *universal* at the server" insight is correct. One correction consistent with
B1: because the main path is **push**, the more fundamental server-side need is
**constant-rate / mixing on the push delivery path** (the roadmap "message mixing" item),
not just a fake-response to a *poll*. The epilogue actually half-says this ("latency
mixing addresses *when*… also needs the server to lie about *whether*"), so it lands —
just note the primitive must live on the push path, not a polling path that isn't the
default.

---

## 4. What the article gets RIGHT (so the critique is calibrated)

- **Threat-model honesty:** SimpleX genuinely does *not* defend the targeted
  known-both-endpoints case and is explicit about defending the mass case via mixing many
  users on busy servers; "quiet servers / few connections" being most exposed is
  consistent with the project's own statements. The doc here defers to the SMP/XFTP/ntf
  threat models for exactly this (`simplex-chat.md:291-295`).
- **Cover must be manufactured; joined-group cover is cancellable** ("any cover the
  adversary can also observe is not cover") — correct and well put; the local threat
  model even notes a group member can *join the same group multiple times* and that
  members can be enumerated, supporting the cancellation argument.
- **Conserved weirdness / relocate-not-eliminate**, **latency-or-bandwidth is
  unavoidable**, **lossy parametric timing model defeats source-linkage where perturbed
  replay does not**, **per-contact secret schedules so the bot's many contacts hide your
  edge** — all sound, and largely independent of the push/poll issue.
- The **bot on a VPS** as a real second endpoint generating receive-side cover is valid
  and unaffected by B5 (a VPS *can* run the always-on scheduled daemon).

---

## 5. Net impact — what would actually have to change

The article's **conclusions** mostly stand, but the **receive-side machinery and its
threat model need rebuilding** on the real architecture:

1. **State the real prerequisite:** to schedule retrieval at all, the fork must **stop
   subscribing and poll with `GET`** — and acknowledge this poll-only client is itself an
   anomaly, is mutually exclusive with `SUB` per queue, and changes the latency model (B1).
   *This is the only genuinely architecture-breaking item.*
2. **Keep the decoys — they work.** Padding + single-TLS multiplexing means decoys give
   real which-queue + presence cover against a wire observer, and which-queue cover against
   the server operator (corrected B2/B3). Just **don't claim they sever timing** — they
   don't; that's the schedule/delay's job (B4).
3. **Still separate the adversaries** (the one surviving part of the old B3): wire observer
   (sees padded multiplexed pairs — which-queue hidden, presence/timing of pairs visible)
   vs. server operator (sees queue IDs) vs. notification server (the `GET`/wake path).
   Each mechanism's value differs by adversary; say which.
4. **Demote "send side is easy"** to "send side is safe only if cover rate/shape
   dominates the contact's arrival rate, and the contact's own side is always observable"
   (B4).
5. **Scope the user's client to a machine they control 24/7** (desktop/VPS), or address
   mobile OS constraints head-on; the phone case is not free (B5) — `simplexmq`'s own docs
   say background mobile delivery requires push and is "unreliable, particularly on iOS"
   (`simplex-messaging.md:392`).

None of these rescue the *targeted global* case (the article already concedes that), but
they're the difference between a scheme that works against the adversary it names and one
that's specified against an architecture SimpleX doesn't run.
