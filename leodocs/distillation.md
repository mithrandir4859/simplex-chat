# SimpleX Chat — Distillation (Top 10 things to know)

The 10 things I'd want someone to tell me on day one, before touching this repo.
Full file-by-file map is in [`inventory.md`](inventory.md). Focus here is the
**Android client**, the **Linux/Desktop client**, and the **Haskell core** they share.

---

### 1. The whole app is a Haskell brain wearing thin client shells

There is **one implementation of all chat logic**: the Haskell core in `src/Simplex/Chat/`.
The CLI, Android, and Desktop apps are shells that load that core as a compiled
**native library** (`libsimplex`) and talk to it. If you're fixing *behavior*
(what a message does, how a group works, what gets stored), you're almost always
in Haskell — even when the bug report says "Android." If you're fixing *how it
looks or feels*, you're in Kotlin.

### 2. Everything crosses one seam: a JSON-over-FFI bridge

The client and core communicate through a tiny, all-important interface:

- **Haskell side:** `src/Simplex/Chat/Mobile.hs` — `foreign export ccall` functions
  (`chat_send_cmd`, `chat_recv_msg`, `chat_migrate_init`, …). Commands go in as JSON
  strings, responses/events come out as JSON strings.
- **Kotlin side:** `apps/multiplatform/common/.../platform/Core.kt` — matching
  `external fun` JNI declarations, with a C shim (`cpp/.../simplex-api.c`) in between.

**Read these two files side-by-side first.** Once you understand this seam, the
whole architecture clicks. `apps/multiplatform/spec/architecture.md` explains it in prose.

### 3. Android and Desktop are ONE codebase (Kotlin Multiplatform + Compose)

Under `apps/multiplatform/`, the `common/` module is ~95% of the client (all the
Compose UI and logic). `android/` and `desktop/` are thin platform shells.
Platform differences use Kotlin's **`expect`/`actual`** pattern — look for paired
files like `Files.kt` (expect) → `Files.android.kt` / `Files.desktop.kt` (actual).
**A UI change usually lives in `common/` and ships to both platforms at once.**

### 4. The three Kotlin files you'll touch constantly

- `common/.../model/ChatModel.kt` — the global observable UI state singleton.
- `common/.../model/SimpleXAPI.kt` — ~150 typed `apiXxx()` calls that build commands,
  cross the FFI, and parse responses (the Kotlin mirror of the Haskell command set).
- `common/.../views/...` — the Compose screens (chatlist / chat / call / settings / groups…).

### 5. The three Haskell files that hold the behavior

- `Controller.hs` — central runtime state (`ChatController`) and core types.
- `Library/Commands.hs` — the command engine; **most feature logic lives here**.
- `Store/` — the encrypted SQLite persistence layer, one module per domain
  (`Messages.hs`, `Groups.hs`, `Direct.hs`, `Profiles.hs`, …).

### 6. Entry points, memorized

- **Android:** process starts in `android/.../app/SimplexApp.kt` (inits the Haskell
  core), UI in `android/.../app/MainActivity.kt` (`setContent { AppScreen() }`).
- **Desktop/Linux:** `desktop/.../desktop/Main.kt` (`fun main()` → loads native lib → `showApp()`).
- **CLI (fastest core test harness):** `apps/simplex-chat/Main.hs` → `simplexChatCLI`.
- **Compose root (shared):** `common/.../App.kt`.

### 7. The GHC version trap (read before you build for Android)

Per `docs/CONTRIBUTING.md`: the `master`/`stable` branches build with **GHC 9.6.3**,
but **Android armv7a** builds from `master-android`/`stable-android` on **GHC 8.10.7**.
The two GHCs differ in available language features (e.g. `OverloadedRecordDot`).
Core code that compiles on your desktop can fail the Android build — keep this in mind.

### 8. How builds actually happen (they're not symmetric)

- **Desktop (Linux):** build the core lib with `scripts/desktop/build-lib-linux.sh`,
  then Gradle `:desktop:packageDistributionForCurrentOS` (→ `.deb`/AppImage via `scripts/desktop/`).
- **Android:** native Haskell libs are **cross-compiled via Nix** (`flake.nix`,
  `scripts/android/build-android.sh`), then Gradle assembles the APK. **The main
  CI (`.github/workflows/build.yml`) does NOT build Android** — it builds CLI/Desktop/macOS.
- Core build plan is `cabal.project`; deps like **`simplexmq`** (the SMP/XFTP
  messaging layer everything sits on) are git-pinned there — **not** git submodules
  (there is no `.gitmodules`).

### 9. There's a docs-as-code layer most repos don't have

`apps/multiplatform/product/` and `apps/multiplatform/spec/` are curated maps from
features → source files. Best starting points: `spec/architecture.md`,
`spec/api.md`, `product/concepts.md`, and `spec/impact.md` (a source→concept
change-impact index). Maintainer-written structure guides live in
`docs/contributing/PROJECT.md` and `docs/contributing/CODE.md`. The dated `plans/`
files are in-flight working notes — useful intent, but not stable specs.

### 10. Privacy/security is the product — respect the invariants

No user IDs; messages are double-ratchet E2E encrypted with an extra routing layer;
the local DB is **SQLCipher-encrypted**; the wire protocol is **versioned with
backward compatibility** (`Protocol.hs`, currently v17). DB schema changes are
**append-only migrations** under `Store/SQLite/Migrations/`, and the schema dump is
**auto-generated by tests** — never hand-edit it. When in doubt, think
adversarially and trace the data flow end-to-end (the project explicitly asks for this).

---

**TL;DR:** Logic = Haskell core (`src/Simplex/Chat/`). UI = one Kotlin/Compose
codebase (`apps/multiplatform/common/`). They meet at the JSON FFI seam
(`Mobile.hs` ↔ `Core.kt`). Build paths differ (Cabal/Nix for the core, Gradle for
the shells), and Android has its own GHC version. Start at `spec/architecture.md`.
