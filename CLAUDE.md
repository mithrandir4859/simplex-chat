# CLAUDE.md

Orientation for Claude (and humans) working in this fork of **simplex-chat**.

This is a Haskell core (`src/Simplex/Chat/`) plus a Kotlin Multiplatform + Compose
client for **Android and Linux/Desktop** (`apps/multiplatform/`). The whole app loads
the compiled Haskell core as a native library and talks to it over a JSON FFI; the
lower network/protocol/crypto layer lives in the separate **simplexmq** repo (a
git-pinned cabal dependency — `cabal.project`).

## Generated analysis & design docs — `leodocs/`

These were produced during an exploratory research session (architecture mapping +
feasibility/design analysis for privacy and remote-use features). They are **analysis
and design notes, not shipped specs.** Protocol-level claims were verified against a
local checkout of `simplexmq` at the pinned commit. Start with the first two.

- **[leodocs/inventory.md](leodocs/inventory.md)** — Detailed, file-by-file inventory of
  the repo (entry points, build scripts, docs, the Haskell↔Kotlin FFI seam), focused on
  Android/Linux/core and skipping iOS/Mac. *Why: onboarding map for someone brand new to
  the codebase.*
- **[leodocs/distillation.md](leodocs/distillation.md)** — The top ~10 things to know,
  free-form. *Why: the day-one TL;DR companion to the inventory.*

- **[leodocs/use-from-desktop-ux.md](leodocs/use-from-desktop-ux.md)** — How the built-in
  "use from desktop" (remote-control / XRCP) feature works and what it would take to drop
  the per-switch QR scan: multicast known-device reconnect already exists; desktop-initiated
  handoff; the Android always-on service; the Syncthing-style 24/7 question; and two
  concrete reconnect designs (network-change-triggered persistent pipe; Syncthing
  file-doorbell as reference-only). *Why: scoping a better, lower-friction desktop↔phone
  reconnect.*
- **[leodocs/blocking-screen.md](leodocs/blocking-screen.md)** — Why the phone shows a
  "disconnect to use here" screen during a remote session, with code pointers: it's the
  single-consumer event stream, **not** a DB-safety guard; what two live UIs would actually
  do; and what altering/removing it requires (event fan-out). *Why: decide whether/how to
  change the block.*

- **[leodocs/syncthing-complexity.md](leodocs/syncthing-complexity.md)** — Feasibility of
  semi-live multi-device DB sync via Syncthing with strict single-active/handoff. The hard
  parts (double-ratchet single-owner, destructive SMP queue draining, no DB merge), the
  lease/handoff protocol, and the fail-closed requirements. *Why: assess a true
  "same account on laptop + phone" sync vs. the limited built-in remote feature.*

- **[leodocs/timing-assumptions.md](leodocs/timing-assumptions.md)** — Adversarial audit of
  a "defend against timing-correlation with a forked client + bot" proposal, checked against
  `simplexmq` source. Confirms the push-not-poll receive model; corrects some of its (and an
  earlier draft's) assumptions; flags the real residuals. *Why: separate what actually
  works from what's specified against an architecture SimpleX doesn't run.*
- **[leodocs/forked-server-timing.md](leodocs/forked-server-timing.md)** — Server-side
  counterpart: a forked SMP server doing **variable, opt-in, cooperative** cover traffic
  (not constant-rate, not full mixing) with schedule-slotted real messages, client-controlled
  delayed delivery + urgency override, and why this isn't obsoleted by mixing at low traffic.
  Includes the code-confirmed QUOTA ceiling on delay. *Why: explore what only a server change
  can buy, and where it still can't reach.*
- **[leodocs/forked-server-timing-v2.md](leodocs/forked-server-timing-v2.md)** — Second
  version, re-grounded against the pinned `simplexmq` (`b981dcb7`) and the full RFC/blog
  corpus. Key reframing: SimpleX **already names this primitive ("noise traffic")** in its
  whitepaper/threat model but never built it, and has a detailed-design delay type
  (`MessageSchedule`) in the super-peer layer. Adds the **21-day message-TTL ceiling**
  (alongside QUOTA), the **delivery-receipt** and **member-send-limit `wait`-throttle**
  breaks, the **commercial-model "zero-knowledge operator" contradiction**, and
  service-session/rotation/short-link/SKEY mechanics v1 missed. *Why: a planning-ready,
  source-verified rewrite with the contradictions and hooks made explicit.*

## Notes
- `simplexmq` is cloned as a **sibling** dir (`../simplexmq`) for verification, per the
  project's own `cabal.project` convention; it is a separately-built dependency, not vendored.
- `justfile` at the repo root is a pre-existing local dev helper, unrelated to these docs.
