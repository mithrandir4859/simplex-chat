# Cooperative, variable-rate cover on a forked SMP server

> Server-side counterpart to `timing-assumptions.md`. The specific idea here is **not**
> constant-rate cover and **not** full message mixing. It is a **forked SMP server that
> cooperates with a forked client to produce per-queue, opt-in, *variable* (human-shaped)
> cover traffic**, into which real messages are slotted, with **client-(semi-)controlled
> delayed delivery** and an **urgency override**. The argument at the end: why this is
> **not** made obsolete by full mixing — and is in fact strictly better in the
> low-traffic / small-server / targeted regime this whole thread cares about.

Grounding (from this repo, see `timing-assumptions.md` §0–1 for verification limits):
the live SMP path **pushes full `MSG` content** over a persistent subscription and the
client `ACK`s; the mobile background path is a separate "wake up and pull" notification.
So cover messages are **real, full-shaped `MSG`s on the live path** — a dummy and a real
message are the same object on the wire — and any per-queue scheduling logic lives on the
push path, not a poll.

---

## 1. Core idea in one line

> The server emits a **predetermined, variable, human-looking** stream of messages on a
> sensitive queue; **real traffic is only ever sent inside slots that stream already
> allows**, so the observable pattern is identical whether or not real content exists —
> and it costs cover bandwidth **only on the queues you mark, only at the rate the
> human-shaped schedule needs**, not a flat constant rate for everyone.

Constant-rate cover is the sledgehammer (always-on, flat, expensive, and itself a
fingerprint — real channels aren't flat). Full mixing is the crowd-dependent approach
(useless without a crowd). This sits between: **self-generated cover, shaped like a
person, scoped to sensitive queues, with real traffic riding the schedule.**

---

## 2. Components

### 2.1 Per-queue "sensitive" marking + cooperative subscription
The client marks specific queues/contacts **sensitive** and negotiates the cover
protocol with the (forked) server for those only. Everything else behaves normally —
**zero overhead on non-sensitive traffic.** This is the key scoping move that makes
variable cover affordable where constant-rate-for-all is not.

### 2.2 The schedule = the silhouette (variable, not constant)
A schedule of emit/deliver events over time that is **bursty, diurnal, and gappy** — i.e.
shaped by the **lossy parametric model** of human messaging from the article (the part
that audit found *sound*). Both sides know it via a **shared seed** (server can derive it)
or the client pushes it (§2.6). The schedule defines *when traffic is observable*; its
realism is what makes the pattern indistinguishable from an organic low-volume user.

### 2.3 Real-fits-in-dummy (token bucket, enforced at the server)
At each scheduled slot the server emits **one message**: a **real** one if any is waiting
and the slot permits, otherwise a **dummy**. A real message that arrives between slots
**waits for the next slot** (latency). Real demand above the schedule's slot-rate
**queues** — classic leaky/token-bucket, now executed by the server. Observable result:
the predetermined variable pattern, always — real existence never changes the shape.

### 2.4 Client-(semi-)controlled delayed delivery to sensitive contacts
When you send to a sensitive contact, the server (acting as your **sending proxy**)
**holds** the message and releases it on the schedule, decoupling your *decision-time*
from the *on-wire emission*. Delay parameters (window, target slot, max hold) are set by
the client — fully or semi automatically. **Verified hook:** SMP already has a real
sender-proxy/relay (`PRXY` command, `ProxyService` party, `sendingProxySMPVersion` —
`simplexmq` `Protocol.hs:576`), originally for hiding sender IP; a forked proxy is the
natural place to add the hold/release. ⚠️ But see §4.9 — you cannot delay past the
recipient queue's capacity without a sender-visible side effect.

### 2.5 Urgency override (deliberate, costed)
A per-message **urgency flag** tells the server to **bypass the hold and send now**. This
is an explicit privacy↔latency trade: an out-of-schedule emission is an **observable
anomaly** ("something happened now"). Mitigations short of raw-immediate: snap urgent
sends to the **nearest upcoming slot** instead of truly now; or pre-provision a denser
"urgent schedule" the user can switch into; or accept the leak for that one message.
The point is the user *chooses* when to spend cover for speed.

### 2.6 Two directions of control (server-conducted vs client-authored)
The send side has to be scheduled too, and there are two clean ways:

- **(a) Server-conducted — instructions ride the dummies.** Each dummy the server pushes
  to the client carries (inside its encrypted body, invisible on the wire) an
  **instruction**: "in N seconds send me a dummy," or "you may send a real message in the
  next slot." The server is the conductor; the client just obeys. Benefit: the **client
  needs no precise always-on timer** — the server's push *cues* it, which partly sidesteps
  the mobile-timer problem *while connected*. Cost: the server drives, and learns, more.
- **(b) Client-authored — schedule pushed, server executes.** The client computes the
  schedule from its **own** behavioral model (keeping its fingerprint client-side) and
  hands it to the server to execute (emit dummies/reals, apply delays). Benefit: the
  client keeps control of the human-shape; the server is a dumb executor. Cost: client
  must define and refresh it.

Both are compatible with the same wire behavior; (a) is better for thin/mobile clients,
(b) for users who don't want the server authoring their behavioral profile.

---

## 3. Why full mixing does **not** make this obsolete

Full message mixing (pool many users' messages, shuffle, delay so inputs can't be linked
to outputs) is powerful **but its anonymity equals the anonymity-set size** — the number
of *other* users' messages it mixes with in the window. That is precisely the quantity a
privacy-niche or personal server lacks. The comparison:

### 3.1 Mixing collapses at low traffic; self-cover does not
> **Confirmed by SimpleX's own design docs.** `simplexmq`'s overview states the router
> "acts as a low-latency mix node" only "**when enough traffic is transiting a router
> simultaneously**," and explicitly: "**we can't rely on this behavior to make a security
> claim**" (`overview-tjr.md:170`). So the project itself concedes mixing is opportunistic
> and traffic-dependent — exactly the gap self-cover fills. Message mixing as a *relied-on*
> feature is **not implemented** (it's the long-standing roadmap item).

- A mix window holding 1–2 messages provides ~**zero** anonymity (one input → one
  output). Mixing's protection is **proportional to concurrent cross-user traffic**.
- The threatened user here is, by assumption, **low-volume on a quiet/niche server** —
  exactly where the mix pool is thin or empty. (This is the article's "quiet servers /
  few connections are most exposed," now applied to mixing itself.)
- **Self-generated dummy cover is independent of other users.** Your real traffic hides
  in *your own* predetermined pattern whether or not anyone else is online. **It works at
  user-count = 1.** You are your own anonymity set.

> During low-traffic periods, hiding in your own dummy traffic is **safer** than relying
> on a small, possibly adversary-populated mix pool. A tiny anonymity set is a false
> sense of security; a self-shaped cover stream is not contingent on strangers.

### 3.2 They are complementary, and a server can blend them
- **Mixing:** cheap cover *when traffic is high* (the crowd pays for you), useless when low.
- **Self-cover:** works at any level (you pay), costs your own bandwidth.
- A smart forked server can **use the real cross-user pool when the anonymity set is
  large enough, and top up with self-dummies when it isn't** — the dummy budget needed
  *shrinks as genuine cross-traffic grows*. Self-cover is the floor; mixing is a discount
  on top when a crowd happens to exist.

### 3.3 It drops the user-count threshold for a server to be private at all
A pure-mixing server needs a **large, steady** user base before it offers meaningful
anonymity. A server offering cooperative dummy cover gives a **single** sensitive user
strong protection **from day one**. This makes **small / personal / family / single-user
servers viable for privacy** — a major deployment advantage, and the inverse of mixing's
"needs a crowd to mean anything."

### 3.4 When mixing *would* dominate (be honest)
Self-cover is the redundant one **only** when *all* of these hold: the server has a
**persistently large, well-distributed** anonymity set 24/7; you're content to **depend
on other users' presence** for your safety; you trust the mix is **honest** (a malicious
mix can simply not shuffle — same trust assumption as a cover server, so not a
differentiator); and you accept mix latency. Those are the **high-traffic public-server**
conditions — **not** the niche/quiet/targeted case this thread is about. In that case
mixing is cheaper and self-cover is unnecessary *for users on that server*. Outside it,
self-cover wins.

**Conclusion:** mixing and cooperative variable self-cover address **different regimes**.
Self-cover is strictly the better tool in the low-traffic / small-server / targeted
regime, and the two compose (floor + crowd-discount) rather than competing.

---

## 4. Concerns (the sharp ones)

### 4.1 🔴 Delivery receipts are a fatal tell unless handled
A dummy is discarded silently by the recipient; a **real** message makes the recipient's
**stock client auto-send a delivery receipt** — an observable downstream event that a
dummy never produces. The local threat model already notes delivery receipts reveal "that
and when a user is using SimpleX." **The scheme must disable (or itself schedule)
delivery receipts for sensitive contacts**, or the receipt path re-introduces exactly the
correlation you removed. This is the most important implementation gotcha.

### 4.2 🔴 The contact's side is still uncovered (existence, not just timing)
Your cover protects **your** queues. The contact runs stock software, so:
- Delaying your send at your proxy decorrelates the **instant** of their receive from your
  decision-time — good.
- But their (stock, push) client still **receives once per real message**, at the
  released slot. So an adversary watching **the contact** sees their queue activate
  **exactly as often as you really message them** — the *delay* hides *when*, not *how
  many / whether*. The contact's stream ≈ your real send stream, time-shifted.
- **Dummy cover toward the contact is impossible unilaterally**: you can't send dummies to
  a stock contact (their client would try to parse them and choke). Covering the contact's
  side requires **contact-side cooperation** (their forked client discards dummies) or
  the contact's **queue hosted on a forked server** that injects dummies. So full edge
  protection remains **bilateral** — same boundary as everywhere in this thread; this
  design cleanly solves *your* side and the *timing* of the edge, not the *existence* of
  the contact's receive events.

### 4.3 🟠 Real and dummy must be byte/behavior-indistinguishable
On the wire SMP's fixed-block padding already makes `MSG`s uniform. But indistinguishability
must hold **end to end**: same size, same `ACK` pattern, same retry behavior, no real-only
side effects (receipts §4.1, notifications, file-fetch follow-ups). Any real-only artifact
re-opens the leak inside an otherwise-perfect slot.

### 4.4 🟠 Urgency override leaks by construction
§2.5 — an out-of-schedule emission says "something happened around now." Acceptable
against a law-bound adversary; against a targeted global one a burst is a burst. Snap-to-
next-slot and pre-provisioned urgent schedules reduce but don't erase it.

### 4.5 🟠 Wire-adversary vs server-compromise are different threats
Crucially, **real-vs-dummy is decided inside the server, in memory.** So:
- A **wire/network adversary** (ISP, hosting provider's network, the contact's-server
  operator) sees only the content-independent output pattern → **defended**.
- A **compromise of your forked server** (memory access, coercion, malicious host with
  root) reveals which slots carried real messages and the sensitive-queue list →
  **not defended.** The server *knows the secret it is hiding.*
This is the central trust trade: you've moved the cover to the one place that can both
*produce* it and *betray* it. Run it yourself, minimize what it persists (schedule in
memory, no real/dummy logs), and treat host compromise as the threat that ends the game.

### 4.6 🟠 Opt-in concentrates a meta-signal ("this user uses cover")
A per-queue cover feature makes the **user** identifiable *to the server* as
privacy-seeking, and possibly to a wire observer if the pattern is distinguishable from
organic. The human-shaped (lossy-model) schedule is exactly what blunts the wire
distinguishability. To blunt the server-side meta-signal, apply **light plausible cover to
many users by default**, so opting-in isn't itself the anomaly — the conserved-weirdness
"make it universal" move, in a cheaper, variable form. Pure opt-in trades bandwidth
savings for a meta-anonymity cost.

### 4.7 🟡 Mobile: server-conducted cueing only works while connected
§2.6(a)'s "dummies cue the client" helps a connected client but **can't reach a Dozing
phone** (the wake-path limit). On mobile, cover degrades to the notification path when
backgrounded; the sensitive client ideally runs always-connected (desktop/VPS), or you
accept reduced protection while the phone sleeps. (A forked **notification** server that
batches/normalizes wake-ups is a separate, necessary companion fork.)

### 4.8 🟡 Schedule knowledge is fine; schedule *violation* is the leak
The adversary *knowing* the schedule doesn't break it — real fits *inside* it, and
real-vs-dummy within a slot is indistinguishable (§4.3). What breaks it is real traffic
**outside** the schedule (urgency, §4.4) or a schedule too thin to contain real demand
(overflow → either added latency or a visible raise). Provision the schedule's peak to the
contact's plausible peak (the per-relationship silhouette idea).

### 4.9 🔴 The QUOTA ceiling: you cannot delay retrieval past your queue's capacity without a sender-visible leak
Code-confirmed and important for the *delay* half of this design. SMP queues have a
**fixed capacity**; when a recipient stops draining and the queue fills, the server
returns **`ERR QUOTA`** to *senders*, and after the recipient finally drains, the server
delivers a **special "quota exceeded" marker message** (`simplex-messaging.md:758`,
`:1037` `msgQuotaExceeded`). Consequences for schedule-bound retrieval:
- If your cover schedule holds/throttles retrieval so messages **accumulate in your
  receive queue beyond capacity**, the **senders observe `QUOTA`** — i.e. anyone messaging
  you (including a sensitive contact, or an adversary probing) **learns you are not
  draining**, which is exactly the "is this user active / delaying" signal the scheme is
  meant to hide. The marker message is also a distinguishable, real-only event (cf. §4.3).
- So the **maximum retrieval delay is bounded by queue capacity ÷ inbound rate**, not by
  your latency tolerance. Long programmed silences (the gap model) collide with this: a
  multi-day "quiet" period while real messages keep arriving will fill the queue and leak.
- Mitigations: keep the *retrieval* schedule dense enough to stay under capacity (drain
  often, even if you **surface** messages to the user on a slower cadence — i.e. decouple
  "server pulls from queue" from "client shows the user"); and/or a forked server that
  raises capacity for sensitive queues (server-side change, fine here) — but raising
  capacity is itself a server-operator-visible config and doesn't help against the
  contact's stock server. **This is the hard ceiling on the "just delay it" instinct.**

---

## 5. What this buys vs the alternatives

| Property | Constant-rate cover | Full mixing | **This (variable cooperative self-cover)** |
|---|---|---|---|
| Works at 1 user / quiet server | ✅ (but flat & costly) | ❌ (needs a crowd) | ✅ |
| Bandwidth cost | High, always-on, all queues | Low (crowd pays) | **Scoped to sensitive queues, human-rate** |
| Looks like an organic channel | ❌ (flat is a fingerprint) | n/a | ✅ (lossy-model shaped, gappy) |
| Hides *your* send timing | ✅ | ✅ (if pool large) | ✅ (server-held + slotted) |
| Hides *your* receive timing | ✅ | ✅ (if pool large) | ✅ (server delivers on schedule) |
| Hides the contact's side | only if contact also covered | only if both in pool | ❌ unilaterally (bilateral needed) |
| Defeats wire adversary | ✅ | ✅ | ✅ |
| Defeats server compromise | ❌ | ❌ | ❌ |
| Low-latency option | ❌ | ❌ | ✅ (urgency, at a cover cost) |

**Net:** a forked server doing *variable, opt-in, schedule-orchestrated* cover is the
right tool for the regime this whole thread targets — **few sensitive contacts, low
volume, delay-tolerant, quiet/personal server.** It dissolves the client-side bot and
decoy machinery (the server controls the receive side directly), it's affordable because
it's scoped and human-rate rather than flat, and it is **not** obsoleted by mixing —
mixing only wins where a large steady crowd already exists, which is exactly the condition
the threatened user doesn't have. The irreducible residuals are the **contact's uncovered
existence leak** (bilateral cooperation needed), **delivery receipts** (must be
suppressed/scheduled), and **trust in your own server** (which now knows the secret it
hides).
