# Making "Use from desktop" not require a QR scan every time

> Question under analysis: the built-in "use from desktop" feature makes you scan a
> QR code seemingly on every switch. Could we instead have a desktop button like
> **"use my account here"** so a Linux user can message from Linux without scanning a
> QR each time?
>
> Short version: **the QR-free reconnect already exists in the codebase** — it's
> multicast rediscovery of an already-paired device — but it's **off by default,
> buried in a sub-screen, and directionally awkward.** The "button" you want is
> ~80% a UX/defaults change, not new protocol. But there's one **fundamental
> constraint** you must understand first, because it changes what the button can mean.

---

## 0. The reframing you need first: who holds the account?

This is the thing that makes the feature confusing. In "use from desktop":

- The **mobile is the _host_** — it holds your account, your database, your identity.
- The **desktop is the _controller_** — a **thin remote UI** that borrows the phone's
  account live over the LAN. **The desktop never has the account.**

(Verified: `RemoteHost` = the phone holding `RCHostPairing`; `RemoteCtrl` = the
desktop; `Remote.hs`, `Remote/Types.hs`.)

**Consequence:** a desktop "use my account here" button can only mean *"connect to my
phone, which is nearby, and show its account here."* It **cannot** make the desktop
work without the phone present and reachable on the network. If the phone is off, far
away, or on another subnet, the desktop has nothing to show. That's not a UX bug —
it's the architecture. (If you want the desktop to be *truly independent* of the
phone, that's a different feature entirely — see §7.)

So the realistic dream is: **"phone in your pocket on the same Wi-Fi → desktop
auto-connects to it with one click (or zero), no QR."** That is achievable, and most
of it is already built.

---

## 1. The good news: QR-free reconnect already exists

The QR is only the **first-pairing handshake**. It carries the controller's ephemeral
session announce + key material so the two devices can establish trust **once**.
After that, the pairing is **persisted**:

- `upsertRemoteHost` / `insertRemoteHost` store an `RCHostPairing { knownHost = ... }`
  with long-term keys (`Remote.hs:220-226`).
- The desktop appears in a **"Linked desktops"** list on the phone
  (`LinkedDesktopsView`, `ConnectDesktopView.kt:410`).

And there is a **no-QR reconnect path** using **LAN multicast discovery**:

- Core: `findKnownRemoteCtrl` → `rcDiscoverCtrl a pairings` (`Remote.hs:408-420`) — the
  phone broadcasts/listens on the LAN, finds a known desktop announcing itself, and
  reconnects using the **stored** pairing. No QR.
- UI already wires it: `findKnownDesktop()` → `controller.findKnownRemoteCtrl()` →
  `connectRemoteCtrl(addr)` (`ConnectDesktopView.kt:466-490`).
- Two preferences already gate it (`ConnectDesktopView.kt:434-440`):
  - **"Discover on network"** = `connectRemoteViaMulticast`
  - **"Connect automatically"** = `connectRemoteViaMulticastAuto`

So the feature you want — *click once, phone auto-found, no QR* — is **literally
present**. The reason it feels like "QR every time" is a combination of defaults,
discoverability, and reliability, not a missing capability.

---

## 2. Why it still feels like "QR every single time"

| Reason | Detail | Fixable by |
|---|---|---|
| **Multicast is OFF by default** | `connectRemoteViaMulticast` / `...Auto` default off; user never finds them | defaults + onboarding |
| **The toggles are buried** | They live inside *Linked desktops → options*, two taps deep, after you've already paired | surfacing/UX |
| **Desktop UI leads with the QR** | `ConnectMobileView` shows the QR + "open on mobile and scan" as the primary path every time (`ConnectMobileView.kt:195-202`) | UX: lead with "wait for known device" |
| **Multicast is genuinely flaky** | many networks block multicast/mDNS (corporate APs, "client isolation" on guest Wi-Fi, VPNs, different subnets, Android battery/Doze suppressing background sockets) | needs a robust fallback (§5) |
| **Verification prompt** | `confirmRemoteSessions` ("Verify connections") adds an emoji/code confirmation step per session unless disabled | a "remember this device" trust option |
| **Possibly re-pairing** | if a session/pairing gets dropped or the user disconnects via the QR button, they fall back to first-pairing = QR again | make reconnect the default, pairing sticky |

**The core insight:** there is no protocol reason to scan a QR after the first pairing
on a cooperative LAN. The friction is product defaults + multicast fragility.

---

## 3. What a "use my account here" button would actually do

Because the desktop is the controller, the button on **desktop** would put the desktop
into **"announce as known controller and wait for my phone"** mode, while the **phone**
(with auto-multicast enabled) discovers and connects to it. Concretely:

**Desktop side ("Use my account here" button):**
1. Start the controller session server and **multicast-announce** itself as a *known*
   host's controller (it already can announce for discovery).
2. Show a lightweight "Looking for your phone on this network…" state instead of a QR.
3. Fall back to revealing the QR/address only if discovery times out (§5).

**Phone side (must be enabled once):**
1. `connectRemoteViaMulticast = true` and `connectRemoteViaMulticastAuto = true`.
2. App (foreground, or via a brief service) runs `findKnownRemoteCtrl` and
   auto-`connectRemoteCtrl` when it hears the desktop.

Net effect: open the desktop app, click once (or have it auto-start), and if the phone
is nearby on the same Wi-Fi it connects within a few seconds — **no QR**. That is the
realistic, in-architecture version of your button.

---

## 4. What's missing to ship that button (the actual work)

Most is UI/defaults; little-to-no new protocol:

1. **Desktop "Use my account here" entry point** 🟡 — a primary button that triggers
   the announce-and-wait flow (reusing existing remote-host start + multicast announce)
   instead of presenting the QR first. New Compose UI + glue to existing APIs.
2. **Flip discovery on by default / first-run opt-in** 🟢 — change
   `connectRemoteViaMulticast(Auto)` defaults, or add a one-time "Make desktop
   automatic?" prompt right after the *first* successful QR pairing (best moment to ask).
3. **"Trust this device" to skip per-session verification** 🟡 — let a known device
   reconnect without the emoji/code step (respect `confirmRemoteSessions`, add a
   per-host "remember" so reconnects are silent).
4. **Phone-side auto-reconnect ergonomics** 🟠 — reliably run `findKnownRemoteCtrl`
   when the desktop wants in. Android background limits mean this is easiest when the
   phone app is foregrounded; fully-backgrounded auto-connect is constrained by Doze.
5. **A non-multicast fallback (the important one)** 🟠 — see §5; without it, "no QR"
   silently fails on the many networks where multicast doesn't work, and the user is
   dumped back to scanning.

---

## 5. The reliability problem (why this isn't already the default)

Multicast/LAN discovery is the weak link, and it's almost certainly *why* SimpleX
keeps the QR as the front-and-center path:

- Many Wi-Fi networks **block multicast / enable client isolation** (guest networks,
  enterprise APs) → discovery never completes.
- **VPNs and different subnets** break it (phone on Wi-Fi, desktop on Ethernet/VLAN).
- **Android Doze / background socket limits** suppress discovery when the phone is
  idle — exactly when you'd want it to just work.
- Multicast announce has **security tradeoffs** (broadcasting presence on the LAN), so
  defaulting it on is a deliberate decision, not an oversight.

**To make "no QR" trustworthy you need a fallback that doesn't rely on multicast:**

- **Remembered direct address.** The desktop's session address (the thing inside the
  QR) can be **pasted** today (`DesktopAddressView` / `paste_desktop_address`,
  `ConnectDesktopView.kt:367-407`). A robust button would **persist the last known
  desktop address per linked device** and try it directly before falling back to QR.
  The pairing keys are already stored; what's missing is remembering a reachable
  address so the phone can dial the desktop without rediscovery.
- **Stable address / fixed port.** If the desktop binds a known port and the phone
  remembers host:port for that linked desktop, reconnect becomes "dial the saved
  address," multicast-free. (Caveat: DHCP changes the desktop IP; mDNS hostname or a
  user-set address helps.)
- **QR only as last resort** — shown when both saved-address and discovery fail.

This fallback layer is the difference between "works on my home Wi-Fi" and "actually
replaces the QR."

---

## 6. Recommended phased plan

1. **Phase 1 — surface what exists (days, low risk).** After first QR pairing, prompt
   "Connect this desktop automatically next time?" → flips `connectRemoteViaMulticast
   (Auto)`. Add a desktop **"Use my account here"** primary button that announces +
   waits, with QR demoted to "show QR code" secondary. This alone removes the QR for
   most same-Wi-Fi home users.
2. **Phase 2 — trust + silent reconnect (medium).** Per-linked-device "remember /
   trust" so reconnects skip verification; auto-attempt known reconnect on desktop
   launch.
3. **Phase 3 — multicast-free fallback (the real win, harder).** Persist last-known
   desktop address per device; reconnect by dialing it directly; only fall back to
   discovery, then QR. This makes "no QR" reliable across networks.
4. **Phase 4 — phone background auto-connect** within Android's limits (foreground
   service while "remote session expected").

---

## 7. The honest limit — and the alternative you might actually want

Even perfected, "use from desktop" is **always phone-tethered**: the desktop is a
window into the phone's live account and needs the phone **present and reachable**.
For a Linux user who wants to message from Linux *as a first-class thing*, that may
still feel wrong — you don't want your laptop dependent on your phone being on the
same Wi-Fi.

If that's the real goal, you don't want better remote-control UX — you want one of:

- **A standalone desktop profile** (the desktop runs its own core/account directly —
  SimpleX supports creating a profile on desktop). Downside: it's a *separate*
  identity from your phone, not the same account.
- **Account migration / DB sync** so the account *lives* on (or is shared with) the
  desktop. This is the harder distributed-systems route analyzed in
  `syncthing-complexity.md` (and the local-WS-server idea in earlier discussion).

So there are two genuinely different wishes hiding in "I want to message from Linux
without scanning a QR":
1. **"Same account, phone nearby, no QR friction"** → fix the remote-control UX
   (this doc, §1–6). Mostly already built; ~weeks of UX work for a great result.
2. **"Desktop independent of my phone"** → not a UX fix at all; it's the
   standalone-account or DB-sync problem (`syncthing-complexity.md`).

---

## 8. Desktop-initiated handoff ("take control here", don't touch the phone)

A separate complaint: even with no QR, you still have to tap **"Use desktop" on the
phone**. You'd rather sit at the desktop and click **"take control from here."** Can
the *desktop* initiate? Answer: **yes at the protocol level, with one catch on the
phone.**

### Who dials whom (the deciding fact)
- **Desktop = the TLS _server_** — it announces and waits (`rcConnectHost`,
  `TLS 'TServer`, `waitForHostSession`, `Remote.hs:188`).
- **Phone = the TLS _client_** — it reaches out and connects (`rcConnectCtrl`,
  `TLS 'TClient`, `connectRemoteCtrl`, `Remote.hs:463/484`).

So at the transport level **the phone always dials; the desktop is the passive
announcing endpoint.** That sounds bad for "desktop initiates," but it isn't, because:

### The desktop-initiate command already exists
`StartRemoteHost (Maybe (RemoteHostId, Bool)) ...` — commented *"Start new or known
remote host **with optional multicast for known host**"* (`Controller.hs:589`). The
`Bool` is the multicast flag. The desktop can already say *"start a session with my
known phone #N and multicast-announce to find it."* A **"take control here"** button
maps almost directly onto this — it's just not surfaced as a button today.

### The catch: the phone has to be *listening* to answer
Because the phone is the dialer, the desktop's announce only completes if something on
the phone is actively discovering and auto-connecting. Today that loop runs **only
while the phone's "Use desktop" screen is open** (`ConnectDesktopView.kt:107`,
`LaunchedEffect → findKnownDesktop`). There is **no background listener** — *that* is
the real reason you must touch the phone, not any protocol limitation.

| Phone state | Desktop "take control" works? |
|---|---|
| App foreground, auto-multicast on | **Basically already** — wire the desktop button to `StartRemoteHost(knownHost, multicast=true)`; phone auto-connects, zero taps |
| Phone asleep, screen off | **Needs new work** — a phone-side background discovery listener (fights Doze; see §9) |

### What it'd take
1. **Desktop "Take control here" button** 🟡 — wire to existing `StartRemoteHost(rhId, multicast=true)`. Small.
2. **Phone background discovery listener** 🟠 — keep discovery alive off-screen so the phone answers unprompted. See §9 for how close we already are.
3. **Optional push-wake** 🔴 — to wake a fully-dozing phone you'd need a notification ping to trigger discovery (the desktop can't reach the phone directly — phone isn't a server). Only needed for the "phone truly asleep" case.

---

## 9. Is the phone already listening? (testing the "it's always running anyway" intuition)

Intuition under test: *"SimpleX already runs all the time on my Android (I allowed
it), so the phone should be fine to listen — we just need to start the discovery
service."* Checked against the code: **mostly right, and it makes this more tractable
than the generic 'Android background is hard' warning — but with two real caveats.**

### ✅ Confirmed: there is a persistent foreground service keeping the core alive
`SimplexService.kt` is a real foreground service: `START_STICKY` (restart if killed),
wake locks, `AutoRestartReceiver`, `onTaskRemoved` reschedules itself, foreground type
`FOREGROUND_SERVICE_TYPE_REMOTE_MESSAGING`. When enabled, **the process stays alive
and the Haskell core + SMP receive loop keep running.** So the heavy part you'd
otherwise dread — keeping the process and core warm — **is already done.** Your
optimism is justified on this point: you would *not* be building background keep-alive
from scratch.

### ⚠️ Caveat 1: "always running" is conditional on notification mode
There are three modes (`NotificationsMode`): **SERVICE** (instant — foreground service
always on), **PERIODIC** (WorkManager wakes it every so often — *not* continuously
alive), and **OFF**. `runServiceInBackground` defaults on, and the "allow battery /
keep running" prompt you accepted puts you in **SERVICE** mode — so for *you*
specifically it's almost certainly genuinely always-on. But the feature couldn't
assume it for everyone; PERIODIC/OFF users wouldn't be listening.

### ✅ Confirmed: discovery is NOT wired into that service
The only remote-ctrl discovery code lives in `ConnectDesktopView.kt` (the UI screen)
and `SimpleXAPI.kt`. `SimplexService.kt` does **message receiving only** — it never
touches remote-ctrl/multicast/discovery. So your phrasing is exactly right: **the
process is alive, the discovery loop just isn't started in it.** Conceptually, adding
it = run `findKnownRemoteCtrl`'s loop from inside the already-running service.

### 🔴 Caveat 2: "process alive" ≠ "Wi-Fi will deliver multicast" — the missing MulticastLock
The concrete blocker your intuition misses: **there is no `MulticastLock` anywhere in
the codebase** (grep for `MulticastLock`/`WifiManager` = nothing). On Android, the
Wi-Fi chip **filters out multicast/broadcast packets to save power** unless the app
holds a `WifiManager.MulticastLock` — and that filtering is most aggressive exactly
when the screen is off. Today's discovery works because you run it **foreground with
the screen on** (where filtering is lax); it was never built to receive multicast in
the background. So enabling background discovery is **not just "start the loop"** — you
must also **acquire a MulticastLock** while listening, and still contend with **Doze**
throttling sockets when the phone is deeply idle.

### Net verdict on the intuition
- **Right:** the process/core is already kept alive (in SERVICE mode), and discovery is
  genuinely just *not started* in the background — so this is more "wire up + lock"
  than "invent background execution." 🟢
- **Incomplete:** you also need a **MulticastLock** (absent today) and **Doze-aware**
  handling for it to actually receive the desktop's announce with the screen off. 🟠
- **Practical upshot:** "phone on the same Wi-Fi, recently used / charging / screen
  occasionally on" → very achievable by starting discovery in the existing service +
  holding a MulticastLock. "Phone dead-asleep in a drawer for hours" → still needs the
  push-wake escape hatch (§8.3). Your 60%-sure hunch is basically correct, and it
  lowers the effort estimate for §8.2 from "hard" toward "moderate."

---

## 10. The Syncthing comparison: the 24/7 service is already there

A sharper version of §9: *"Syncthing runs 24/7 on my phone with a persistent
notification — why can't SimpleX do the same for discovery?"* It already can, because
**SimpleX uses the exact same Android mechanism Syncthing does.**

### ✅ The always-on service + persistent notification already ships
`SimplexService.kt` is a foreground service with an **ongoing notification**
(`createServiceNotification` + `.setOngoing(true)`, ~line 191), `START_STICKY`,
`AutoRestartReceiver`, `onTaskRemoved` self-reschedule, and wake locks. In
instant-notifications (**SERVICE**) mode it runs **24/7 with a notification — identical
in kind to Syncthing's.** This is the part that's normally hard and fragile, and it's
**done and battle-tested.** You'd be hanging one more job on a service that already
runs, not building background execution.

### The two small gaps to make discovery 24/7
1. **Attach the discovery loop to the service** 🟢 — today `findKnownRemoteCtrl`'s loop
   runs only on the "Use desktop" screen; move it into the running service.
2. **Hold a `MulticastLock`** 🟠 — still absent in the codebase; required to *receive*
   multicast with the screen off (see §9). A few lines, but mandatory, plus Doze
   handling.

### 🔴 The asymmetry no Kotlin change fixes: Syncthing has relays, remote-control doesn't
Syncthing is reliable *from anywhere* not because of its notification but because it
has **global discovery servers + relay servers** — it never depends on the LAN.
SimpleX remote-control has **no relay and no global rendezvous**: discovery is **LAN
multicast only** (`rcDiscoverCtrl`), and the only off-LAN path is **pasting the
desktop's address manually** (`connectRemoteCtrl(addr)`). So even a perfect 24/7
listener helps **only on the same Wi-Fi as the desktop**; off-LAN it buys nothing.
That gap is missing *infrastructure*, not a Kotlin fix.

| Piece | Status |
|---|---|
| 24/7 foreground service + persistent notification | **already shipping** (SERVICE mode) — same as Syncthing |
| Run discovery on it continuously | **small** Kotlin change |
| Receive multicast with screen off | **small–moderate** — add `MulticastLock` + Doze handling |
| Reconnect when phone is *off the LAN* | **not Kotlin** — needs relay/discovery infra SimpleX doesn't run for remote control |

**Upshot:** on home Wi-Fi, "phone listens 24/7, desktop takes control with one click"
is achievable with modest Kotlin riding on the existing service. Syncthing-style
reconnect-from-anywhere is the only part out of reach without new infrastructure.

---

## 11. Proposed reconnect designs (the synthesis)

The reframe from §10 is the foundation: **the phone isn't allergic to listening —
it's allergic to *re-finding*.** Receiving over a connection it opened, watching a
local file, and reacting to system events are all things it does reliably 24/7.
Multicast rediscovery is the one thing it's bad at. So both designs below **avoid
rediscovery** and lean on outbound connections + local triggers.

**Correctness note (carry this over, don't confuse the two tracks):** in
remote-control the account *always* lives on the phone and the desktop is just a live
window — **keeping the pipe open is safe; there is no single-writer rule, no
split-brain, no corruption risk.** That rigor (hard-pause the other side) belongs to
the *DB-sync* track in `syncthing-complexity.md`, **not** here. Here, pipe lifecycle is
purely a UX/battery question.

### ✅ Design A — Network-change-triggered persistent pipe (the shippable one)

This combines "persistent pipe" and "open it on joining home Wi-Fi" into **one**
design — they aren't separate ideas; the network-change event is simply *what opens
(and closes) the pipe.* No external dependencies — Android-native primitives only.

- **Trigger:** `ConnectivityManager.NetworkCallback` registered in the
  **already-running** foreground service fires when the phone joins (or leaves) Wi-Fi.
  Event-driven, negligible battery — no polling, no continuous radio listening.
- **Address (no Syncthing):** on the join event the phone gets the laptop's current
  LAN address from, in order of niceness: (1) last-known cached address, (2) a **short
  multicast burst** — acquire `MulticastLock` for a few seconds only, which is cheap
  and where screen-off filtering barely matters because *the phone initiated an active
  burst*. (A continuous background multicast listener — the thing that fights Doze —
  is exactly what this design avoids.)
- **Action:** phone **dials the laptop outbound** (the reliable direction), pipe
  established, kept open while on the LAN, dropped on leave.
- **Desktop side:** "Take control here" = `StartRemoteHost(knownHost, multicast=true)`
  (§8). The desktop announces; the phone — already connected via the pipe, or dialing
  on the join trigger — responds with no tap.
- **Net experience:** walk in the door → within seconds the desktop can take control,
  zero phone interaction, no continuous multicast, minimal battery.

**Why this is the one to build:** every piece is a standard Android capability
(`NetworkCallback`, the existing foreground service, outbound TLS, an optional brief
multicast burst). Nothing the user must install. This is what a shippable feature
looks like.

### 📎 Design B — Syncthing file-doorbell (reference/example only — NOT shippable)

Kept for reference because it cleanly illustrates the principle, **but it is a
workaround, not a product feature.**

- **How:** laptop writes `controller-available.json {ip, port, ts, nonce}` into a
  Syncthing-synced folder; the phone watches that **local file** (inotify in the
  running service) and dials out when it changes.
- **Why it's elegant:** it dodges multicast *entirely* — the phone listens to a **local
  file**, not the network, and Syncthing's own persistent pipe does the delivery (the
  observed 3–10s). None of the radio/`MulticastLock`/Doze problems apply. Security is
  fine: the file is only an address hint; connecting still needs the stored pairing
  keys.
- **Why it can't ship:** it **forces every user to install and configure Syncthing
  just for this one feature** — an absurd product dependency. Great for a personal /
  self-hosted setup (e.g. the author's own machine); unacceptable to impose on users.
- **What to take from it:** the doorbell file is just *"an always-on out-of-band
  channel that delivers the address."* Design A internalizes that role with a
  network-change trigger; a future option could internalize it with an **SMP-based
  signaling channel** (reuse the messaging pipe the phone already holds open 24/7 —
  see §10's "persistent signaling pipe" idea) to remove even the LAN-only limit. Same
  pattern, no third-party dependency.

### Plan: build **Design A** (network-change-triggered persistent pipe, no Syncthing).
Keep **Design B** documented as the reference example that proved "doorbell beats
rediscovery," and as the template for a later SMP-signaling version.

---

## 12. Bottom line

- The protocol **already supports** QR-free reconnect to a known device via multicast;
  pairings are persisted and there's a "Linked desktops" list. **You are not blocked
  by the protocol.** 🟢
- The "QR every time" pain is **defaults + buried toggles + multicast fragility**, not
  a missing feature. 🟡
- A **"Use my account here"** button is mostly a **UX/defaults change** (Phase 1) that
  would remove the QR for typical same-Wi-Fi use almost immediately; the genuinely
  hard part is a **multicast-free fallback** (Phase 3) to make it reliable on *any*
  network. 🟠
- **Fundamental constraint:** the desktop stays phone-tethered no matter how slick the
  button is. If you want true desktop independence, that's the separate
  account-migration / DB-sync track, not this one. 🔴

The "insane UX" is real, but it's the easy kind of hard: the machinery is there; it
just needs to be turned on, surfaced, and given a fallback.
