# SimpleX Chat — Repository Inventory

> Onboarding inventory for a developer **new to the project**, focused on the
> **Android client**, the **Linux/Desktop client**, and the **Haskell core** that
> both clients call into. iOS/macOS-specific code is intentionally skipped.
>
> Paths are given relative to the repo root (`/var/home/shared/Projects/simplex-chat`).
> A companion high-level summary lives in [`distillation.md`](distillation.md).

## What this project is (30-second version)

SimpleX Chat is a privacy-first messenger with **no user identifiers**. The
**entire app logic lives in a Haskell core library** (`src/Simplex/Chat/`). Every
client — the terminal CLI, Android, and Desktop — is a thin shell that loads the
compiled Haskell core as a **native shared library** (`libsimplex.so`/`.dll`/`.dylib`)
and talks to it over a **JSON command/response FFI**. The Android and Linux/Desktop
apps share a single **Kotlin Multiplatform + Compose** codebase under
`apps/multiplatform/`. Understanding the **FFI seam** (Kotlin `Core.kt` ↔ Haskell
`Mobile.hs`) is the key to understanding the whole repo.

```
 Kotlin/Compose UI (apps/multiplatform/common)
        │  external fun  (JNI declarations in platform/Core.kt)
        ▼
 C shim (common/src/commonMain/cpp/.../simplex-api.c)
        │  links
        ▼
 libsimplex  ←  Haskell core (src/Simplex/Chat/Mobile.hs : foreign export ccall)
        ▼
 ChatController → Library.Commands → Store (SQLite) → simplexmq agent (SMP/XFTP)
```

---

# 1. Top-level entry points & build config (repo root)

### README.md
Project landing page: what SimpleX is, install links for every platform, security model overview. Read for context, not for building.

### CHANGELOG.md
Human-readable version history (current line: 6.5.4). Good for seeing what shipped recently.

### simplex-chat.cabal
The Haskell build manifest (generated from a package.yaml by hpack). Defines the `simplex-chat` **library**, the executables (`simplex-chat` CLI + the bots/directory service), and the `simplex-chat-test` test suite. Build flags: `swift` (iOS JSON), `client_library` (library-only, no CLI), `client_postgres` (Postgres instead of SQLite).

### cabal.project
The Haskell build plan. Pins Hackage index-state and, crucially, **pulls the core dependencies as git source-repository-packages** (not git submodules — there is no `.gitmodules`). The most important pin is **`simplexmq`** (the SMP/XFTP messaging protocol + agent that the chat core is built on), plus forks of `direct-sqlcipher`, `sqlcipher-simple`, `hs-socks`, `haskell-terminal`, `aeson`, etc.

### flake.nix / flake.lock
Nix flake driving **reproducible builds**, especially the **cross-compiled Android native libraries** (aarch64 + armv7a) via haskell.nix. Also defines Linux/macOS toolchains and GHC 9.6.3. This is how the Haskell core gets compiled for Android.

### fourmolu.yaml
Config for `fourmolu`, the Haskell autoformatter (2-space indent). Run before committing Haskell.

### libsimplex.dll.def
Windows DLL export list — the canonical list of FFI symbols the core exposes. Build scripts validate the Haskell `foreign export`s against this file.

### Dockerfile / Dockerfile.build
Container images used for reproducible Linux CLI/Desktop builds (GHC, Cabal, NDK, Gradle).

### install.sh
Convenience installer script for the CLI / dependency setup.

### justfile (untracked, local-only)
**Your own scratch dev-helper** — `just` recipes for launching the Android emulator, managing `screen` sessions, and an `apk-build` recipe. References a `jd/companion` directory that is not part of this repo. Not part of upstream SimpleX; safe to treat as personal tooling.

---

# 2. Haskell core — `src/Simplex/Chat/` (the brain)

> Everything the clients can do is implemented here. If a feature behaves a
> certain way, the truth is in this tree, not in the Kotlin UI.

### src/Simplex/Chat/Mobile.hs ⭐ FFI GATEWAY
The C FFI boundary for **all** non-terminal clients (Android, Desktop, iOS). Exports ~21 functions via `foreign export ccall` — `chat_migrate_init` (open DB + create controller), `chat_send_cmd`/`chat_send_cmd_retry` (JSON command in → JSON response out), `chat_recv_msg`/`chat_recv_msg_wait` (blocking event stream), plus parse/file/media helpers. Uses a `StablePtr` to keep the `ChatController` alive across calls. **Start here to understand client↔core.**

### src/Simplex/Chat/Mobile/ (File.hs, Shared.hs, WebRTC.hs)
Supporting code for the mobile FFI: C-string marshalling helpers, mobile file ops, and WebRTC encryption helpers exposed to clients.

### src/Simplex/Chat/Controller.hs ⭐ STATE HUB
Defines `ChatController` — the central runtime state (TVars for queues, current user, locks, agent client, config). Also defines `ChatCommand`, `ChatEvent`/`ChatResponse`, `ChatError`, `ChatConfig`, `ChatOpts`. Everything flows through a `ReaderT ChatController`.

### src/Simplex/Chat/Library/Commands.hs ⭐ COMMAND ENGINE
The largest piece of logic: parses and executes every chat command (create user/group, send message, join, accept contact, etc.) and emits events. `execChatCommand` is the main entry. This is where most feature behavior lives.

### src/Simplex/Chat/Library/Subscriber.hs
Background subscriber loop that processes incoming agent messages/events and turns them into chat events.

### src/Simplex/Chat/Library/Internal.hs
Shared internal helpers used across the command/subscriber logic.

### src/Simplex/Chat.hs
High-level facade / startup: `defaultChatConfig`, database creation, `newChatController`. The wiring that assembles the controller before commands run.

### src/Simplex/Chat/Types.hs + Types/ ⭐ DOMAIN MODEL
The core data model: `User`, `Contact`, `GroupInfo`, `GroupMember`, `ChatItem`, `Profile`, `Preferences`, etc. Subdir adds `Preferences`, `MemberRelations`, `UITheme`, `Shared`. Read alongside Controller.hs.

### src/Simplex/Chat/Protocol.hs
The on-the-wire chat protocol: message/event encodings (`x.msg.new`, `x.mem.new`, …) and **version negotiation** (currently up to v17). Critical for backward compatibility. See also the spec in `src/Simplex/Chat/protocol.md`.

### src/Simplex/Chat/Messages.hs + Messages/ (Batch, CIContent/)
Message and chat-item content modeling, batching/encoding, and the `CIContent` event types that describe what a chat item *is* (text, file, call, member event…).

### src/Simplex/Chat/Store/ ⭐ DATABASE LAYER
The SQLite (SQLCipher-encrypted) persistence layer, one module per domain: `Messages.hs` (biggest — queries/pagination), `Groups.hs`, `Direct.hs`, `Profiles.hs`, `Files.hs`, `Connections.hs`, `ContactRequest.hs`, `NoteFolders.hs`, `Delivery.hs`, `RelayRequests.hs`, `Remote.hs`, `Shared.hs` (SQL utilities).

### src/Simplex/Chat/Store/SQLite/Migrations/
~60 schema migrations named `M<YYYYMMDD>_<desc>.hs`. **Migrations are append-only**; the schema dump is auto-generated by tests — don't hand-edit schema SQL.

### src/Simplex/Chat/Store/Postgres/Migrations/
Parallel Postgres migration track, only compiled under the `client_postgres` flag (used for server-side/bot deployments, not the mobile apps).

### src/Simplex/Chat/View.hs
Renders `ChatResponse`/events into JSON (for clients) and styled text (for the terminal). Large file; the formatting layer.

### src/Simplex/Chat/Terminal/ (Main.hs, Input.hs, Output.hs, Notification.hs)
The **terminal/CLI UI**. `Main.hs` exposes `simplexChatCLI` — the entry the CLI executable calls. The fastest way to exercise the core without a GUI.

### src/Simplex/Chat/Remote/ (Protocol, Transport, RevHTTP, Multicast, Types, AppVersion)
"Connect a mobile to desktop" remote-control feature — lets one device drive another's chat session over the local network.

### src/Simplex/Chat/Markdown.hs
Message markdown + URI parsing/sanitization (also exposed over FFI as `chat_parse_markdown`).

### src/Simplex/Chat/Call.hs
WebRTC call state/signaling on the core side.

### src/Simplex/Chat/Operators*.hs (+ Operators/Conditions, Presets)
Preset server "operators" (e.g. SimpleX Chat / Flux) and their usage conditions — the network operator selection users see in onboarding.

### src/Simplex/Chat/ — other notable modules
`Files.hs` (file send/receive), `Bot.hs` (bot framework hooks), `Archive.hs` (export/import), `Stats.hs`, `AppSettings.hs`, `ProfileGenerator.hs` (random profile names), `Options*` (CLI/DB option parsing), `Delivery.hs` (delivery receipts), `Util.hs`, `Help.hs`, `Styled.hs`.

### src/Simplex/Chat/protocol.md
ABNF spec of the chat protocol message syntax — the human-readable companion to `Protocol.hs`.

---

# 3. CLI & bot executables — `apps/`

### apps/simplex-chat/Main.hs
The terminal client executable: a thin wrapper that calls `simplexChatCLI`. Good reference for how to boot the core minimally.

### apps/simplex-chat/Server.hs
Optional WebSocket server wrapper (run the chat core as a local network service that clients connect to over WS).

### apps/simplex-bot/, simplex-bot-advanced/, simplex-broadcast-bot/, simplex-directory-service/, simplex-support-bot/
Example/production bots built on the core (`Main.hs` each). `simplex-directory-service` is the group-discovery directory bot. Secondary to client work but useful as compact API usage examples.

### apps/ios/
iOS SwiftUI app — **out of scope, skip.**

---

# 4. Android + Linux/Desktop client — `apps/multiplatform/`

> One Kotlin Multiplatform + Jetpack Compose codebase. `common/` holds ~95% of
> the code (UI + logic); `android/` and `desktop/` are thin platform shells.

## 4a. Multiplatform top-level

### apps/multiplatform/README.md
Build/run quick-start: `./gradlew assembleDebug` (Android), `packageDistributionForCurrentOS` (Desktop), native-lib build, testing, localization. **Read this first for building the apps.**

### apps/multiplatform/CODE.md
Architecture + coding standards for the Kotlin codebase: the expect/actual pattern, module layout, the product/spec/source three-layer doc governance, and the change protocol.

### apps/multiplatform/settings.gradle.kts
Declares the three Gradle modules — `:common`, `:android`, `:desktop` — and plugin versions/repos.

### apps/multiplatform/build.gradle.kts
Root Gradle script: shared Java version, Haskell RTS options, Maven repos, `local.properties` overrides.

### apps/multiplatform/gradle.properties
Pinned versions and app version codes: Kotlin 2.1.20, Compose 1.8.2, AGP 8.7.0, JVM 11; Android 6.5.4 (353), Desktop 6.5.4 (145).

### apps/multiplatform/local.properties.example
Template for local overrides (APK compression, debuggable flag, app-name suffix, mac signing). Copy to `local.properties`.

### apps/multiplatform/gradlew / gradlew.bat
Gradle wrapper (use this, not a system Gradle).

## 4b. Shared code — `apps/multiplatform/common/`

Source sets: `commonMain` (shared), `androidMain` (`*.android.kt` actuals), `desktopMain` (`*.desktop.kt` actuals), plus `cpp/` for the JNI shim. The `expect`/`actual` keyword pair is how platform specifics are injected.

### common/build.gradle.kts
The multiplatform module config: `androidTarget()` + `jvm("desktop")`, Compose, serialization, Moko resources, and the CMake hookup that builds the JNI wrapper around the prebuilt Haskell `libsimplex`.

### common/src/commonMain/kotlin/chat/simplex/common/platform/Core.kt ⭐ THE KOTLIN SIDE OF THE FFI
`external fun` JNI declarations matching `Mobile.hs`: `chatMigrateInit`, `chatSendCmdRetry`, `chatRecvMsg`, `chatParseMarkdown`, file/crypto helpers, `initHS`. **The Kotlin↔Haskell seam — pair this file with `src/Simplex/Chat/Mobile.hs`.**

### common/src/commonMain/kotlin/chat/simplex/common/model/SimpleXAPI.kt ⭐ API DISPATCH
The `ChatController` Kotlin object: ~150 typed `apiXxx()` functions that build commands, call across the FFI, and parse responses. Also `AppPreferences` (150+ persisted settings keys). This is the Kotlin-side mirror of the Haskell command set.

### common/src/commonMain/kotlin/chat/simplex/common/model/ChatModel.kt ⭐ UI STATE
A `@Stable object` singleton holding all observable app state (current user, chats, active chat, calls, members, onboarding…) as Compose `MutableState`/`SnapshotStateList`. The single source of truth the Compose UI reads.

### common/src/commonMain/kotlin/chat/simplex/common/App.kt
Compose root — `AppScreen`/`MainScreen` and top-level navigation. Where the UI tree starts.

### common/src/commonMain/kotlin/chat/simplex/common/AppLock.kt
App lock / authentication gating (passcode/biometric).

### common/src/commonMain/kotlin/chat/simplex/common/platform/ (expect declarations)
~19 platform-abstraction files: `AppCommon.kt` (`initChatController`, `runMigrations`), `Files.kt` (data/tmp/db paths), `Platform.kt` (`PlatformInterface` runtime hook), `Notifications.kt`/`NtfManager.kt`, `VideoPlayer.kt`, `RecAndPlay.kt`, `Share.kt`, `Cryptor.kt`, `Images.kt`, `Log.kt`, `UI.kt`. Each has matching `.android.kt`/`.desktop.kt` actuals.

### common/src/commonMain/kotlin/chat/simplex/common/views/ (the UI, ~170 files)
All Compose screens, grouped by feature:
- **chatlist/** — chat list, previews, search, tags, user picker
- **chat/** + **chat/item/** — message list, the composer (`ComposeView`/`SendMsgView`), and per-type item rendering (text/image/video/voice/file/call/member events)
- **chat/group/** — group/channel member management, links, moderation
- **call/** — call UI + `WebRTC.kt` signaling
- **newchat/** — new chat / add group / QR connect
- **usersettings/** (incl. **networkAndServers/**) — settings, appearance, privacy, SMP/XFTP/proxy config
- **database/** — DB view, encryption, backup, migration
- **onboarding/**, **localauth/**, **remote/**, **migration/**, **helpers/** (ModalView, AlertManager, AppUpdater), **chatlist/.../theme** (ThemeManager, colors)

### common/src/commonMain/cpp/android/CMakeLists.txt + simplex-api.c ⭐ ANDROID JNI SHIM
Builds `libapp-lib.so` from `simplex-api.c`, linking the prebuilt `libsimplex.so` + `libsupport.so` (per ABI under `libs/<abi>/`). This C file is the literal JNI bridge implementing the methods declared in `Core.kt`.

### common/src/commonMain/cpp/desktop/CMakeLists.txt + simplex-api.c ⭐ DESKTOP JNI SHIM
Same idea for Desktop: builds the JNI wrapper linking prebuilt `libsimplex.{so,dll,dylib}` per OS/arch.

### common/src/commonMain/resources/MR/
Moko-resources strings — base + ~21 translations. Where UI text lives.

### common/src/androidMain/ … AppCommon.android.kt
Android actuals — most importantly the Haskell init path (`initHaskell` / `System.loadLibrary("app-lib")`) and Android implementations of players, files, notifications, share, etc.

### common/src/desktopMain/ … DesktopApp.kt, AppUpdater.kt, StoreWindowState.kt
Desktop actuals: `DesktopApp.kt` (`showApp()` Compose window + layout), in-app `AppUpdater.kt`, window-geometry persistence, and `.desktop.kt` player/file/notification implementations (VLCJ for media).

## 4c. Android shell — `apps/multiplatform/android/`

### android/build.gradle.kts
The Android app module: compileSdk 35 / minSdk 26 / targetSdk 35, ABI filters (arm64-v8a, armeabi-v7a), signing, APK compression, and the CMake hook to `common/.../cpp/android/CMakeLists.txt`.

### android/src/main/AndroidManifest.xml
Declares `chat.simplex.app`, the `SimplexApp` Application, `MainActivity`, services (`SimplexService`, `CallService`), boot/update receivers, deep-link intent filters (`simplex://`, `https://simplex.chat/`), and icon aliases.

### android/src/main/java/chat/simplex/app/SimplexApp.kt ⭐ ANDROID ENTRY (process)
Custom `Application`: initializes the Haskell core (`initHaskell(packageName)`), runs DB migrations, sets up background workers and lifecycle observers. First code that runs.

### android/src/main/java/chat/simplex/app/MainActivity.kt ⭐ ANDROID ENTRY (UI)
The single `FragmentActivity`: handles notification/deep-link intents, edge-to-edge, orientation, and renders the shared Compose UI via `setContent { AppScreen() }`.

### android/src/main/java/chat/simplex/app/SimplexService.kt
Foreground service that keeps the core running to receive messages in the background (persistent notification).

### android/src/main/java/chat/simplex/app/CallService.kt + views/call/CallActivity.kt
Call lifecycle service and the dedicated full-screen call Activity.

### android/src/main/java/chat/simplex/app/MessagesFetcherWorker.kt
WorkManager periodic background fetch for when the foreground service is disabled.

### android/src/main/java/chat/simplex/app/model/NtfManager.android.kt
Android notification implementation (channels, NotificationManager).

### android/src/main/res/
Icons (all DPIs + dark_blue theme variants), adaptive launcher icons, `locales_config.xml` (21 langs), `xml/file_paths.xml` (FileProvider), colors/themes/ringtone.

## 4d. Desktop (Linux) shell — `apps/multiplatform/desktop/`

### desktop/build.gradle.kts
Compose Desktop application config: main class `chat.simplex.desktop.MainKt`, distribution targets (Linux **Deb**/AppImage via scripts, plus Dmg/Msi), CMake cross-compile hookup, native-lib resource layout.

### desktop/src/jvmMain/kotlin/chat/simplex/desktop/Main.kt ⭐ DESKTOP ENTRY
`fun main()`: single-instance guard, loads the native Haskell lib via `System.load(...)`, inits the runtime + migrations, wires the updater, then calls `showApp()`. The Linux/Desktop counterpart to `SimplexApp.kt`.

### desktop/src/jvmMain/resources/distribute/
Linux packaging assets: `SimpleX.desktop` (launcher entry), `chat.simplex.app.appdata.xml` (AppStream metadata), and `simplex.{png,ico,icns}` icons.

## 4e. Docs-as-code — `apps/multiplatform/product/` and `spec/`

### apps/multiplatform/product/
Product-level docs mapping user-facing capabilities to source: `README.md`, `concepts.md` (PC1–PC30 concept map — a good navigation index), `glossary.md`, `rules.md`, `gaps.md`, plus `views/` (per-screen) and `flows/` (multi-step user journeys).

### apps/multiplatform/spec/
Technical spec for the Kotlin client: `architecture.md` (the JNI bridge + lifecycle — **read this**), `state.md` (ChatModel), `api.md` (~150 API functions), `database.md`, `impact.md` (source→concept change-impact map), plus `client/` and `services/` subdirs (navigation, calls, theme, files, notifications). The most useful client docs in the repo.

---

# 5. Build & release scripts — `scripts/`

### scripts/android/build-android.sh ⭐
Main reproducible Android APK build: builds the cross-compiled Haskell native libs (via Nix), unpacks them per-ABI, then runs Gradle to assemble. Companions: `build-android-bundle.sh` (AAB for Play Store), `compress-and-sign-apk.sh`, `download-libs.sh` / `prepare.sh` (fetch/unpack prebuilt native libs), `lib.txt`.

### scripts/desktop/build-lib-linux.sh ⭐
Builds the Haskell core `libsimplex.so` for Linux with Cabal and validates its FFI exports against `libsimplex.dll.def`/`flake.nix`. **Run this before building the Desktop app from source.** Mac/Windows variants exist alongside.

### scripts/desktop/make-deb-linux.sh, make-appimage-linux.sh, build-cli-deb.sh
Package the Desktop app as `.deb` / AppImage, and the CLI as `.deb`.

### scripts/desktop/prepare-vlc-linux.sh
Bundles VLC libs the Desktop app needs for media playback. (Windows/mac variants + `prepare-openssl-windows.sh` also present.)

### scripts/cabal.project.local.linux
Linux Cabal overrides (SQLCipher/OpenSSL flags) — copy to `cabal.project.local` for local core builds.

### scripts/nix/
Nix support: `sha256map.nix` (dependency hashes), dependency patches (`direct-sqlcipher-*.patch`, etc.), `update-sha256.awk`.

### scripts/db/
SQLite↔Postgres migration tooling: `pg2sqlite.py`, `sqlite.load` (pgloader config), and a `README.md` guide.

### scripts/ci/
CI helpers (mostly mac signing + Linux disk cleanup) — `linux_util_free_space.sh` is the Linux-relevant one.

### scripts/simplex-chat-reproduce-builds.sh / -android.sh
Top-level orchestrators that reproduce official CLI/Desktop and Android builds in Docker and emit SHA256-verified artifacts.

---

# 6. CI — `.github/`

### .github/workflows/build.yml
The main pipeline: builds + tests the **Haskell CLI**, builds **Linux Desktop** (.deb + AppImage) and the Postgres library variant, builds macOS, and cuts releases. **Note: the Android APK is NOT built here** — Android native libs come from Nix/Hydra and are assembled separately (see `scripts/android/`).

### .github/workflows/ (others)
`reproduce-schedule.yml` (scheduled reproducibility check), `cla.yml` (contributor agreement), `web.yml` (website). `.github/actions/` holds reusable `prepare-build`/`prepare-release` composite actions; `CODEOWNERS` defines ownership.

---

# 7. Documentation — `docs/`

### docs/CONTRIBUTING.md ⭐
Branching model and GHC compatibility — **important gotcha:** `master`/`stable` use **GHC 9.6.3**, but Android armv7a builds from `master-android`/`stable-android` on **GHC 8.10.7** (different language features, e.g. `OverloadedRecordDot`). PR scopes: ios/android/desktop/core/docs/website/ci.

### docs/contributing/PROJECT.md ⭐
Repository structure guide from the maintainers — the official version of this inventory's map (core in `src/`, client in `apps/multiplatform/`, etc.).

### docs/contributing/CODE.md
Coding standards: fourmolu, adversarial security thinking, type-driven design, trace data flows end-to-end before changing.

### docs/ANDROID.md
How to pull/inspect the Android app's data (ADB backup, decrypting the SQLCipher DB). Operational, not build-focused.

### docs/CLI.md
Terminal app usage — the quickest way to drive the core by hand.

### docs/SERVER.md
Full guide to self-hosting an SMP relay server (install, Docker, Tor, certs). Server-ops, not client dev.

### docs/WEBRTC.md
Configuring custom STUN/TURN servers for calls.

### docs/protocol/ (simplex-chat.md, channels-protocol.md, channels-overview.md)
Protocol specifications, including the newer **channels** feature.

### docs/rfcs/
100+ dated design RFCs (2021→2026) — identity, groups, relays, post-quantum crypto, channels, etc. Where features are designed before implementation.

### docs/guide/
End-user guide (connections, messages, groups, profiles, calls, settings, data management).

### docs/ — other
`ABOUT.md`, `SIMPLEX.md`, `WHY.md` (philosophy/design), `GLOSSARY.md`, `FAQ.md`, `SECURITY.md` (audits), `DIRECTORY.md`, `THEMES.md`, `TRANSLATIONS.md`, `dependencies/` (incl. `HASKELL.md`), `lang/` (translated docs). Plus `CHANGELOG`-adjacent reference docs.

---

# 8. Planning docs — `plans/`

### plans/ (≈55 dated `*.md` files)
In-flight feature/bugfix planning docs named `YYYY-MM-DD-<topic>.md` (most from 2026). **These are working design notes, not stable docs** — treat as snapshots of intent. Android/Desktop-relevant examples: `2026-04-17-kotlin-share-channel-link.md`, `2026-03-29-desktop-text-selection.md`, `2026-04-02-desktop-voice-recording.md`, `2026-05-09-desktop-tray-implementation.md`, `2026-04-06-onboarding-cards-compose.md`. Also broader ones like `chat-relays-mvp-launch-plan.md` and several `*coverage*` test-planning docs. (No repo-wide AI prompt files or CLAUDE.md exist; the closest things to inventories are `apps/multiplatform/product/concepts.md` and `spec/impact.md`.)

---

# 9. Other (lower priority for client work)

### packages/
Language bindings/SDKs over the core: `simplex-chat-nodejs` (Node bindings, used by bots), `simplex-chat-python` (new Python SDK), `simplex-chat-client` (shared client types), `simplex-chat-webrtc` (browser WebRTC for calls).

### bots/
Bot framework, examples, and API specs (`README.md`, `src/`, `api/`). See also the bot executables under `apps/`.

### eth/
Ethereum/NFT integration experiments — minor.

### website/, blog/, fastlane/, assets/, images/, media-logos/
Marketing website (11ty), blog content, F-Droid/Play store metadata (fastlane), and brand/image assets. Not app code.

---

# Where to start reading (suggested order)

1. **This file** + `distillation.md` → the lay of the land.
2. `apps/multiplatform/spec/architecture.md` → the client↔core bridge, explained.
3. `src/Simplex/Chat/Mobile.hs` ↔ `common/.../platform/Core.kt` → the FFI seam, both sides.
4. `common/.../model/SimpleXAPI.kt` + `ChatModel.kt` → how the UI talks to the core and holds state.
5. `src/Simplex/Chat/Controller.hs` + `Library/Commands.hs` → where core behavior lives.
6. Android entry: `SimplexApp.kt` → `MainActivity.kt`. Desktop entry: `desktop/.../Main.kt`.
7. `docs/CONTRIBUTING.md` for the **GHC 9.6.3 vs 8.10.7 (Android)** branch gotcha before building.
