# inventory-docs.md

A file-by-file inventory of the **markdown documentation in this repo, excluding
`leodocs/`** (the `leodocs/` analysis notes have their own index in
[CLAUDE.md](../CLAUDE.md)). Each entry gives the doc's path and a 2-5 sentence
summary of what it contains.

**Scope:** substantive docs only. This intentionally omits the 59 auto-generated
TypeDoc API stubs under `packages/simplex-chat-nodejs/docs/`, the translation
mirrors under `docs/lang/**` and `blog/lang/**` (copies of the English docs in
cs/fr/pl/fr-fr), and the per-dependency license-text files under
`docs/dependencies/licences/**`.

**Note on the app docs:** the `apps/ios/product/`+`spec/` and
`apps/multiplatform/product/`+`spec/` trees are structurally parallel — the same
topics documented per platform — but every file differs in content. Both are
inventoried below.

## Contents

- [Root](#root)
- [docs/ (top-level)](#docs-top-level)
- [docs/guide/](#docsguide)
- [docs/protocol/](#docsprotocol)
- [docs/contributing/](#docscontributing)
- [docs/dependencies/](#docsdependencies)
- [docs/rfcs/](#docsrfcs)
- [plans/](#plans)
- [apps/simplex-support-bot/plans/](#appssimplex-support-botplans)
- [blog/](#blog)
- [bots/](#bots)
- [App bot & service READMEs](#app-bot--service-readmes)
- [apps/multiplatform/ (Android + Desktop)](#appsmultiplatform-android--desktop)
- [apps/ios/](#appsios)
- [packages/](#packages)
- [website/](#website)
- [scripts/](#scripts)
- [Misc](#misc)

---

## Root

### README.md
The main project README for SimpleX Chat, billed as "the first messaging platform that has no user identifiers of any kind." It covers installation across iOS, Android, F-Droid, and a terminal/CLI app on Linux/macOS/Windows, plus how to connect to the team, join user groups via the SimpleX Directory, and make private connections. It highlights the privacy/security model (double-ratchet E2E encryption, metadata protection, no user profile IDs) and links to translation, contribution, and donation sections, along with third-party audit and recommendation badges.

### PRIVACY.md
The SimpleX Chat Operators Privacy Policy and Conditions of Use, formatted as a website page (Eleventy front matter, served at `/privacy`). It explains the network design and general privacy principles, then details what data lives only on your device vs. what transits or is temporarily stored on relay servers, private message delivery that hides IP/connection graph, iOS push-notification limitations, and the preset server operators and what they may share. It closes with the Conditions of Use that users must accept and the source-code license/update terms.

### CLAUDE.md
Orientation doc for Claude and humans working in this fork. It describes the architecture (Haskell core in `src/Simplex/Chat/` loaded as a native lib by a Kotlin Multiplatform + Compose client for Android/Desktop, communicating over a JSON FFI, with the network/crypto layer in the sibling `simplexmq` repo) and indexes the generated `leodocs/` analysis and design notes on privacy and remote-use features. It also notes that `simplexmq` is a separately-built sibling dependency and that the root `justfile` is a pre-existing dev helper.

### CHANGELOG.md
A "Release History" file listing SimpleX Chat versions in reverse-chronological order (e.g., v6.5, v6.4), each with a date, a short bulleted list of user-facing features and improvements, and a link to the corresponding release blog post. It is a per-release feature summary aimed at end users rather than a granular commit log.

## docs/ (top-level)

### docs/ABOUT.md
Short "About us" page for SimpleX Chat Ltd, stating the company's mission to build a fully decentralized network giving users full control of their identity, contacts, and communities. Provides contact channels: an in-app/SimpleX address, a PGP-encryptable email (with fingerprint), and links to the project's social media accounts.

### docs/ANDROID.md
A how-to guide for accessing the files SimpleX stores in its private Android data directory (databases, sent/received files, temp files, preferences). It walks through using ADB to back up app data, enabling app data backup, optionally changing the random database passphrase, extracting the backup archive, and decrypting the SQLCipher databases with `sqlcipher` to inspect tables.

### docs/BUSINESS.md
Guide to using SimpleX Chat for business and customer service via business addresses (added in v6.2), which combine direct-chat and group features so multiple agents can join a customer conversation. Covers customer broadcasts, promoting community groups in the directory, and key limitations (data-loss responsibility, no multi-device profile use, group-owner recovery). Includes technical advice for running the CLI in the cloud via tmux and controlling remote profiles from the Desktop app over SSH.

### docs/CLI.md
Documentation for the SimpleX Chat terminal (console) app on Linux/macOS/Windows. Covers features, two-layer E2E encryption, installation (install script, prebuilt binaries, Docker, or building from Haskell source), and usage including running the client, routing through Tor, connecting via invitations, groups, file sending, and long-term user contact addresses.

### docs/CODE_OF_CONDUCT.md
A brief code of conduct emphasizing engineering excellence, prioritizing user needs, and merit-and-respect-based collaboration. Lists guidelines (iterative contribution acceptance, equal treatment, constructive criticism, staying on-topic and avoiding politics/FUD) and notes that violations may lead to warnings, bans, or removal at maintainers' discretion.

### docs/CONTRIBUTING.md
Top-level contributing guide stressing that changes must address real user problems and that plans should be discussed early. Points to the structure/coding docs in `docs/contributing/`, explains compiling with SQLCipher and OpenSSL on macOS, documents the project's git branches (stable/master/android variants) and the development/release process, PR naming/scopes, GHC 8.10.7 vs 9.6.3 differences, and forward/backward JSON compatibility for remote desktop connections.

### docs/DIRECTORY.md
Describes the SimpleX Directory, an experimental service for discovering user-created public groups via the website, onion link, or a directory bot. Explains how to search, how group owners add/remove a group (inviting the directory service as admin, adding its link to the welcome message, approval within ~24h), and the content policy restricting which groups can be listed and why.

### docs/DONATIONS.md
A donations appeal page thanking supporters and reaffirming that SimpleX protocols remain open and public domain. Mentions the forming SimpleX Network Consortium/Foundation and lists ways to donate (GitHub Sponsors, OpenCollective, BTC/XMR/ETH/USDT addresses), plus a pointer to comment on the SimpleX Community Credits sustainability plan.

### docs/DOWNLOADS.md
Download hub listing where to get the latest SimpleX apps from GitHub releases (or the git.simplex.chat mirror). Provides per-platform links for the desktop app (Linux AppImage/Flatpak/deb, Mac, Windows), mobile apps (iOS App Store/TestFlight, Android Play Store/F-Droid/APKs), and the terminal app, with notes on verifying/reproducing Linux and Android builds.

### docs/FAQ.md
A frequently-asked-questions page organized into How-to-use, Troubleshooting, and Privacy-and-security sections. Covers connecting to people, finding groups, databases, files, incognito profiles, invitations, message ticks/read receipts, cross-platform profile use, and topics like post-quantum cryptography, why a profile can't be shared across devices, what data can be disclosed, and IP-address protection.

### docs/GLOSSARY.md
An alphabetical glossary defining technical terms relevant to choosing a private messenger (e.g., 2-factor key exchange, anonymous credentials, blockchain, centralized vs federated networks, message padding). It notes the definitions are factual but reflect SimpleX's privacy-and-security-focused perspective.

### docs/JOIN_TEAM.md
A recruiting page inviting people to join the SimpleX Chat team to build secure, private, decentralized communications. Lists open roles (iOS Engineer, Android/Desktop Application Engineer, Community Builder, etc.), the kinds of exceptional self-driven achievements applicants should submit, and that positions are full-time remote contracts within UTC +/- 8 hours.

### docs/LINKS.md
A curated list of community publications about SimpleX Chat (reviews, comparisons, podcasts), each entry giving the outlet, type, a short summary, language, date, and URL. Examples include a Help Net Security product showcase, a State of Surveillance secure-messaging comparison, and a Citadel Dispatch podcast with Evgeny Poberezkin.

### docs/REPRODUCE.md
Instructions for verifying and reproducing SimpleX release builds. Covers obtaining the build signing key from keyservers and confirming its fingerprint (cross-checked against ENS/Mastodon/Reddit), verifying release signatures, and reproducing server binaries, Linux desktop/CLI apps, and Android APKs.

### docs/SECURITY.md
The project's security policy. Describes prior Trail of Bits assessments, how to privately report security issues (PGP-encrypted email, not public channels), the threat model and out-of-scope attack classes, issue triage, severity/difficulty classification, the disclosure/notification timeline, and the trusted-partners pre-notification program.

### docs/SERVER.md
A guide to hosting your own SMP (SimpleX Messaging Protocol) server. Its table of contents covers an overview, quick start with a systemd service, installation options (script, manual, Docker, Linode marketplace), binary verification, configuration, server security (key handling, certificate rotation), Tor setup, the info/statistics pages, build reproduction, updating, and pointing the app at the server.

### docs/SIMPLEX.md
A motivation-and-comparison document for the SimpleX platform. It lays out the privacy/metadata problems with existing chat platforms and explains SimpleX's solution: storing messages and contacts only on client devices and using disposable unidirectional message-queue addresses rather than any user identifiers, with pointers to the whitepaper and the network's privacy advantages.

### docs/THEMES.md
Explains app color themes (currently configurable/exportable only in the Android app) and how to contribute a theme via pull request. Steps include exporting the theme file, importing a provided sample database, taking three specified screenshots, and amending this file; it also showcases the included dark-blue "SimpleX" theme.

### docs/TRADEMARK.md
The SimpleX Chat trademark policy covering the name and logo. Lists permitted contexts (communities/events, addresses/entities, publications, compatibility statements) and prohibited ones (software branding/forks, implied affiliation, commercial use), plus usage guidelines (mark unofficial uses, keep the logo unmodified) and a reservation of all trademark rights.

### docs/TRANSLATIONS.md
A guide for contributing UI translations via Weblate. Covers prerequisites (Weblate account tied to the GitHub email, signing the contributor license agreement, joining the translators group) and the recommended process of translating the Android app first (which seeds the iOS glossary), with notes on the time commitment and Weblate gotchas.

### docs/TRANSPARENCY.md
A transparency-report page (updated Feb 2026) from SimpleX Chat Ltd describing its handling of law-enforcement data requests. It states that 12 such requests in 2025 yielded no responsive information, reiterates the goal of having essentially no user data or metadata available for disclosure, and links to privacy/whitepaper/audit resources.

### docs/WEBRTC.md
A guide to deploying and configuring custom WebRTC STUN/TURN ICE servers for SimpleX Chat calls. It walks through setting up `coturn` on Ubuntu, obtaining TLS certificates via Let's Encrypt, and editing the coturn configuration.

### docs/WHY.md
A short manifesto-style essay, "Why we are building SimpleX Network," arguing that online platforms have eroded the natural pre-internet privacy of conversation. It frames SimpleX as a network with no phone numbers, usernames, accounts, or user identities of any kind that carries encrypted messages without knowing who is connected, restoring users' ownership and sovereignty over their communications.

### docs/XFTP-SERVER.md
A guide to hosting your own XFTP (SimpleX File Transfer Protocol) server. After an overview of XFTP's metadata-protecting design (asynchronous delivery, padded E2E encryption, fixed-size chunks across relays), it covers installation options (systemd, Docker, Linode), Tor setup, configuration, server address/control-port/statistics documentation, updating, and configuring the app to use the server.

## docs/guide/

### docs/guide/README.md
The SimpleX Chat User Guide landing page and quick start, linking to the other guide chapters (sending messages, secret groups, chat profiles, managing data, calls, privacy/security, app settings). The quick start walks through creating a device-local first chat profile and choosing a notifications mode.

### docs/guide/app-settings.md
A reference for the app's settings screens. It explains how to open settings and details the "You" section (active profile, chat profiles, incognito) and other settings, noting behaviors such as profile updates being sent to all non-incognito contacts and recommendations for display-name formatting.

### docs/guide/audio-video-calls.md
Guide to making end-to-end encrypted audio and video calls with contacts over WebRTC (group calls are not supported). Covers how to initiate audio and video calls and the options available when accepting an incoming call.

### docs/guide/chat-profiles.md
Explains chat profiles, which are stored only locally on the device. Covers creating additional profiles, and (per later sections) hiding and muting profiles, a feature added in v4.6.

### docs/guide/making-connections.md
A work-in-progress guide on connecting with people given that SimpleX has no user identifiers, so others can only reach you via a one-time or temporary address (QR code or link). Describes optional long-term SimpleX contact addresses, accepting/rejecting/auto-accepting requests, and compares one-time invitation links with reusable contact addresses.

### docs/guide/managing-data.md
Covers managing local chat data: automatic message deletion after a set period (local-only, per-profile) and the chat database settings. Details the database passphrase (random by default, must be set manually to export) and app data backup.

### docs/guide/privacy-security.md
Lists the features and options affecting privacy and security, noting the defaults balance privacy, security, and convenience. Explains security-code verification to defend against MITM attacks on invitation links (comparing or scanning codes between contacts) and points to the privacy/security settings.

### docs/guide/secret-groups.md
Describes secret groups, which are anonymous and private with each message/file sent separately to every member (so best suited to smaller groups). Covers creating a group, group preferences (disappearing messages, direct messages, delete-for-everyone, voice messages), and adding members.

### docs/guide/send-messages.md
A how-to for sending, editing, and deleting messages. Covers sending plain text, editing/quoting via tap-and-hold, and sending images and files via the paperclip button (camera, gallery, or file picker).

## docs/protocol/

### docs/protocol/channels-overview.md
Revision 1 (2026-04-28) design overview of SimpleX Channels, a relay-mediated feature for stateful information delivery and management. Covers what channels are and their use as a transport layer, content visibility and participant privacy, architecture (state/distribution, identity/ownership, governance, roles), cryptographic primitives, security objectives and threat model with current gaps, and an extensive future-work section.

### docs/protocol/channels-protocol.md
Revision 1 (2026-04-28) protocol specification for SimpleX Channels as currently implemented, building on the SimpleX Chat Protocol with extensions for relay-mediated distribution and Ed25519 message signing. Details channel creation (root/member key generation, deterministic link creation, link-data upload), relay acceptance/addition, subscriber connection, message signing and forwarding, the binary batch format, delivery pipeline, deduplication, and channel-as-sender messages.

### docs/protocol/simplex-chat.md
The SimpleX Chat Protocol specification (Revision 2, 2024-06-24, by Evgeny Poberezkin), defining the application-level message format and client operations layered on top of SMP and the SimpleX Messaging Agent protocol. Covers supported chat functions (direct/group messages, replies, edits, forwards, deletions, attachments, group management, WebRTC call signaling) and message formats (JSON, compressed, binary), with XFTP used for file transfer.

## docs/contributing/

### docs/contributing/CODE.md
Coding and building guidance shared across the simplexmq and simplex-chat repos. Covers adversarial/threat-model thinking for security, Haskell code style with fourmolu (formatting rules, qualified imports, comment policy, minimal diffs, type-driven development that avoids duplicated function bodies), end-to-end data-flow analysis during review, key GHC extensions, cabal build commands and flags, and the custom forked external dependencies.

### docs/contributing/PROJECT.md
A map of the simplex-chat repository structure for working with the code. Describes the project overview (decentralized, no user identifiers), key components (Haskell core, terminal CLI, multiplatform/iOS apps, bots, website), core Haskell modules, the database migration workflow (including auto-generated schema files), test structure, key forked dependencies, and build commands for Android/Desktop, iOS, and the website.

## docs/dependencies/

### docs/dependencies/README.md
A short index of SimpleX Chat and server dependencies, listing SQLCipher (encrypted SQLite), VLC (media player library for calls), and WebRTC, each with its license, and linking to the full Haskell dependency report.

### docs/dependencies/HASKELL.md
An auto-generated Haskell dependency license report for the `simplex-chat` executable. It tabulates direct and indirect transitive dependencies with versions, SPDX license IDs, descriptions, and which packages depend on each (noting GHC 9.6.3 bundled/core libraries in bold and a few entries with missing license metadata, e.g. simplexmq, direct-sqlcipher, sqlcipher-simple).

## docs/rfcs/

Dated design proposals, in chronological order.

### docs/rfcs/2021-12-11-identity.md
Proposes an optional identity layer for SimpleX Chat that maps a memorable, human-shareable address to an email address the user controls, preserving SimpleX's metadata-privacy and address-portability goals while avoiding email's drawbacks. An identity server (accessed via chat clients over SMP, with no separate UI) verifies email ownership, provisions per-address SMP queues, acts as an anti-spam/anti-DoS proxy, and forwards connection requests without learning who is contacting the user. The doc details product requirements (sub-addresses via `+` extensions, sender verification, MITM-detection by the owner) and a preliminary SMP-based protocol for provisioning addresses and routing contact requests.

### docs/rfcs/2022-01-26-mobile-app.md
Addresses how to port the existing Haskell SimpleX Chat core to iOS/Android while keeping platform-specific differences in the core minimal. It weighs design options for the UI↔Haskell FFI seam and proposes a single string/JSON-based `sendRequest` function for commands/queries plus a blocking `receiveMessage` function the UI polls in a loop for events. It also covers database access (route through Haskell to avoid SQLite concurrency issues), DB initialization, multiple profiles in one database, and forward-looking notes on push notifications.

### docs/rfcs/2022-02-10-deduplicate-contact-requests.md
A short implementation plan for deduplicating repeated contact requests that arrive via the same contact link. It proposes adding `via_contact_uri_hash` and `xcontact_id` fields to connections (and `xcontact_id` to contact_requests/contacts), generating a random per-join identifier sent in the `XContact` message, so the client can detect repeat joins and update an existing pending request (e.g., new server/profile) instead of creating duplicates.

### docs/rfcs/2022-02-24-servers-configuration.md
An implementation plan for letting users configure their own SMP servers instead of only the hard-coded defaults. It outlines moving the server list into mutable agent Env state, adding a `smp_servers` DB table plus `GetServers`/`SetServers` chat commands, and wiring this through the mobile UI (settings view with validation and a restore-defaults option) and terminal client (`-s` option overrides stored servers).

### docs/rfcs/2022-03-02-avatars.md
A brief implementation plan for adding optional profile/avatar images to user and group profiles. It lists the steps: a DB migration touching `contact_profiles` and `group_profiles`, a nullable `Maybe` field on `User` in Types.hs, command parsing changes, a new `APIUpdateProfile` JSON command, and wiring to the mobile apps — with images stored as base64-encoded data passed via JSON.

### docs/rfcs/2022-03-02-number-chat-items.md
Addresses the need to reference prior messages in a conversation to support features like replies/quoting, edits, deletions, receipts, and group message integrity. It proposes adding a random, non-sequential per-sender, per-conversation `msgId` to all chat messages and an optional `msgRef` to messages that reference others, with a JTD schema for quoted replies. The format is designed for backward compatibility, so clients that don't support quoting simply render the message normally and ignore the `quote` property.

### docs/rfcs/2022-04-20-video-calls.md
Proposes adding encrypted audio/video calling between already-connected SimpleX contacts. The approach uses WebRTC for peer-to-peer media (run in in-app webviews with JavaScript), while call signaling (SDP/ICE negotiation) is carried securely over the existing SimpleX channel via a new "call" message type, with optional additional frame-level encryption of media. It also lists open questions around STUN/TURN server hosting, IP-exposure warnings, and an initial throwaway prototype with no API changes.

### docs/rfcs/2022-05-28-chat-item-integrity.md
Addresses surfacing SMP agent message-integrity events (skipped, duplicate, out-of-order, or bad-hash messages) to mobile users, since there was previously no data-model support to persist them (they only appeared in the terminal). The solution distinguishes item-level integrity errors (saved as item metadata/status) from skipped-message errors (created as separate chat items shown in the UI). The referenced PR initially implements only the skipped-message chat item, leaving other integrity errors as terminal-only events.

### docs/rfcs/2022-06-03-portable-archive.md
Addresses safe database migration (for notifications support) and database export/import by performing migration via an export/import flow to avoid data loss. It proposes implementing archive creation and restoration in Haskell, with the app only supplying source/target folders, and defines a ZIP archive structure (chat DB, agent DB, and a files folder) plus a UTC-timestamped filename convention.

### docs/rfcs/2022-08-10-incognito-connections.md
Addresses connecting to new contacts without exposing the user's main profile, using the same account. It proposes an incognito mode (plus a per-connection switch) and parameterized connect APIs, comparing two implementation options: generating a random per-connection profile (Option 1) versus sending no profile and letting the other side assign a local name (Option 2). It also covers schema changes, not broadcasting profile updates to incognito contacts, UI indications, and extending incognito behavior to group invitations/memberships.

### docs/rfcs/2022-08-26-group-connections-recovery.md
Addresses recovering group connection establishment that fails on bad network/IO, where (unlike direct connections) the user can't simply retry because many connections are created automatically per joining member. The favored proposal makes agent commands (`createConnection`, `joinConnection`, `allowConnection`) asynchronous with correlation IDs: chat saves a correlation ID plus a "continuation" to the database, and resumes processing when the agent reports completion or when a status change is detected on subscription. It enumerates the specific message-handling sites in the group join flow that need this recovery.

### docs/rfcs/2022-08-29-database-encryption.md
Proposes encrypting the chat and agent SQLite databases using SQLCipher as a drop-in replacement, with forked `direct-sqlcipher`/`sqlcipher-simple` libraries. Migration between plaintext and encrypted databases uses `sqlcipher_export()`, the key is passed via chat command/agent config and validated with a test query (PRAGMA key), and a backup/rollback step protects against migration failure. It defines settings options to encrypt, decrypt, or rekey (change passphrase) the database, with an empty passphrase meaning unencrypted.

### docs/rfcs/2022-09-06-send-small-files.md
Addresses the high overhead and slowness of sending small files, which currently require a separate connection handshake and multiple online presences. The solution sends small files inline over the existing message connection, with two modes: `FIInvitation` (recipient explicitly accepts, then the file is delivered inline) and `FIChunks` (file sent right after the message without acceptance, by prior per-contact agreement, useful for voice messages/gifs). It defines a `fileInline` property on `FileInvitation` plus new `XFileAcptInline` and `XFileChunks` messages to coordinate inline chunk delivery.

### docs/rfcs/2022-09-20-chat-history-deletion.md
Addresses indefinite chat-history retention causing privacy concerns and growing storage use. It proposes optional scheduled deletion of chat items and files via a configurable TTL (None/Day/Week/Month), initially as a global setting with possible per-conversation TTL later. The implementation plan covers a `ChatItemTTL` enum, `Set/GetChatItemTTL` APIs, a background expiration thread in the ChatController whose interval is recomputed when the TTL changes, a `settings.chat_item_ttl` column, and reuse of existing delete logic — plus open questions about thread management and platform differences (e.g., iOS not being long-running).

### docs/rfcs/2022-09-22-chat-settings.md
Addresses per-contact/per-group feature permissions and configuration, focusing specifically on asymmetric remote settings (set unilaterally but relevant when sending), such as permission to send voice messages, images, or to edit/delete sent messages and for how long. The solution broadcasts a `preferences` dictionary alongside the profile in `x.info` (and `x.grp.info` for groups), with clients ignoring unknown values for forward compatibility. It defines the JSON schema, database columns (user/group/contact preferences, distinguishing sent vs received), Haskell types, and `/_set prefs` APIs, with voice messages as the first implemented preference.

### docs/rfcs/2022-10-10-group-links.md
Addresses friction in joining "public" groups, where each member must currently be manually invited via an existing member. The solution introduces group links — a new type of contact-address link with auto-accept enabled, so that accepting a join request via the link automatically invites the contact to the group, letting owners publish a shareable link. It discusses design trade-offs (per-member vs. owner/profile-level links, including group metadata in the link, incognito membership) and the implementation (a `group_id` column on `user_contact_links` plus create/delete/show group-link APIs).

### docs/rfcs/2022-10-19-group-contacts-management.md
Addresses problems with SimpleX automatically creating a direct contact connection for every joining group member: undesirable in large/low-trust groups, MITM risk when the host introduces members, inability to delete member contacts while the group exists, and unwanted visible contacts from group-link joins. The proposed solution makes direct-connection creation optional (a group-owner and/or user setting, with backward-compatibility handling), allows deleting group-member contacts (e.g., setting `contact_id` to NULL or marking deleted), and hides/filters group-link contacts and pending connections on both inviting and joining sides.

### docs/rfcs/2022-12-12-disappearing-messages.md
Proposes per-conversation disappearing messages with a configurable TTL that locally deletes both sent and received messages after they're read/sent. It covers turning the feature on/off (via the preferences framework or, alternatively, ad-hoc `XMsgTtl*` protocol messages for offer/agree/off), owner-set behavior in groups, and special interactive chat items for agreeing/disagreeing on changes. The design adds a `delete_at` column and index on `chat_items`, a `disappearingItems` thread map plus a `cleanupManager` background process that schedules per-item deletion threads (and bulk-deletes already-expired items), with the UI showing a countdown timer.

### docs/rfcs/2022-12-17-user-profiles.md
Addresses supporting multiple user profiles within a single database (separate communication contexts with no shared metadata), which previously required switching databases and restarting and meant events for non-active profiles were missed. The solution keeps transport connections separate per profile (unshared even on the same servers) and adds APIs to list and switch the active user. The design works through subscribing to all users' connections to receive events, tagging events with the originating user (`UserChatResponse`), per-user handling of chat-item expiration/disappearing messages/calls, and per-user storage of network and other settings, noting the DB schema already supports multiple users.

### docs/rfcs/2023-04-28-files-encryption.md
Addresses the fact that received files are stored unencrypted on disk while the database is encrypted. Proposes app-level (rather than platform/system) encryption: encrypt files on receipt and expose C APIs to the mobile clients to read/copy files with on-the-fly decryption for previews, voice/video playback, and saving to device. Recommends a random per-file key stored in the (already-encrypted) database over deriving keys from the storage key, to simplify key management and incremental rollout.

### docs/rfcs/2023-04-28-multiplatform.md
Plans a standalone desktop client (replacing the terminal-only desktop) that mirrors the mobile architecture: a Compose Multiplatform (JetBrains) UI over the Haskell core, running JVM-only initially. It weighs JVM pros/cons and lays out migration steps: restructuring to Gradle `.kts`, splitting code into Android/desktop/common parts, stubbing hardware features, and implementing video/audio/camera/QR via vlcj-based libraries plus rebuilding the WebRTC stack with SimpleX's custom WebRTC build.

### docs/rfcs/2023-05-02-groups.md
A foundational design exploration for scaling and making groups consistent, since the current full-broadcast/fully-connected model scales linearly in traffic and offers no group-wide integrity or conflict resolution. It proposes modeling a group as a replicated distributed state machine with a Merkle DAG of events (favoring causal "Approach 1" ordering), separate handling of profile/membership/messages, and consensus only for the rare conflicting events (member removal, role/profile changes). For dissemination it proposes epidemic/gossip-style randomized multi-hop forwarding to achieve roughly O(log N) scaling with quantified per-message fan-out.

### docs/rfcs/2023-05-22-groups-moderation.md
Tackles the abuse downside of anonymous group participation (spam/inappropriate content, and re-joining under new identities) that current basic moderation can't stop in public link groups. Proposes two combinable approaches: a community/group reputation-score system that gates participation for new members and grows with positive engagement, and discovery/search servers that enforce moderation policies (admin rights, controlled join links, required group policies, automated content recognition). Both depend on the group-state consistency improvements from the earlier groups RFC.

### docs/rfcs/2023-05-30-rotation-improvements.md
Improves SMP connection "switch" (queue rotation): currently the switch state is opaque to chat, and triggering multiple switches before the first completes leaves orphaned queues. Proposes persisting detailed per-direction switch status (new `rcv_switch_status`/`snd_switch_status` columns with granular `RcvSwitchStatus`/`SndSwitchStatus` enums) in the agent, surfacing it to the UI via a renamed `ConnectionInfo`, and adding logic to stop/abort/re-trigger switches safely (including a `QERR`/`SPFailed` mechanism for permanent failures).

### docs/rfcs/2023-07-25-contact-groups.md
Addresses the poor UX of using SimpleX from multiple devices and the lack of cross-device sync, especially that adding devices to a 1-to-1 chat currently requires creating a group. Rather than full device synchronization, it proposes reusing group technology to add a user's own devices to 1-to-1 conversations. It compares two approaches: upgrading an existing contact to a group versus maintaining a managed "my devices" list (with a new contact-group invitation link type), weighing migration and automation trade-offs.

### docs/rfcs/2023-08-10-groups-wt-contacts.md
Targets the traffic waste of creating two connections (group + direct contact) per group member when direct messages are off by default, plus the inability to re-establish a deleted direct connection. It compares three alternatives: reusing group connections for direct messages (rejected as breaking the chat/agent model and the planned sparse-group relaying), creating direct connections only on demand, or creating them only when the group setting allows. It leans toward on-demand/setting-gated creation (via a new `XGrpDirectInv` message), preserving connection isolation.

### docs/rfcs/2023-08-26-ios-notifications.md
Diagnoses iOS notification crashes as caused by concurrent SQLite access between the main app and the Notification Service Extension (NSE), which keeps running and can create new connections (notably for member connections) after the app returns to foreground. Proposes suspending the NSE when the app resumes (e.g. via shared prefs or Mach messages) and possibly WAL mode, plus a scheme where NSE-created connections are marked "requiring subscription" without auto-subscribing so the main app subscribes later, which would require changes through the whole stack including the SMP protocol.

### docs/rfcs/2023-08-28-groups-improvements.md
Optimizes the unstable, traffic-heavy group handshake where joining members eagerly create connections to all members and the host sends unbatched introductions. Proposes a new handshake: the joining member publishes one temporary per-group address, the host batches introductions, and per-member `MemberCode` tokens prevent impersonation during connection (new messages like `XGrpAcptAddress`, `XGrpMemInvCode`, `XGrpMemFwdCode`, `XIntroduced`). It also streamlines group-link joins (no host contact, dummy placeholder group), proposes sending direct messages over group connections, and discusses per-group "chat protocol version" gating for client compatibility.

### docs/rfcs/2023-09-12-group-member-contacts.md
Refines the ability to send direct messages to group members without creating separate direct connections, while preserving the UX of distinct conversations. It adds a `MessageScope` (group vs direct) to `ExtMsgContent` and introduces "member contact" records (via `APICreateMemberContact`) that reuse the group member's connection and must be unmergeable across groups. It works through edge cases: pre-existing regular contacts, cascade-delete/connection-retention rules when members leave, distinguishing member contacts in the UI, and dropping messages from removed members.

### docs/rfcs/2023-09-12-remote-profile.md
Proposes letting a "thin" desktop UI control a "master" mobile device that holds all data and does the communication, solving multi-device sync by relaying the existing text+JSON chat-core RPC over a secure channel instead of true sync. It defines a session lifecycle (discovery via QR/UDP, TLS+cryptobox handshake, activity relaying, reconnect, disposal) with the mobile as single source of truth and (initially) a locked mobile UI during sessions. It details the proposed mobile/desktop UX flows and notes caveats around connectivity restrictions, traffic/compression, and honeypot discovery threats.

### docs/rfcs/2023-09-25-groups-integrity.md
A deep dive into group message integrity so that members can detect when someone sends different messages to different members and can fill in missed-message gaps. It proposes embedding per-message sequential IDs plus parent IDs and hashes (`MsgIds`/`MsgParentId`) to form an integrity DAG, with `XGrpRequestSkipped`/`XGrpRequested` to fetch missing parents, and sketches DB tables and a `GroupMsgIntegrity` result type. It raises many open questions: which protocol level carries the IDs, 16KB block size limits, abuse via mass skip-requests, metadata leakage, and whether eventual/partial integrity is even worth showing in the UI.

### docs/rfcs/2023-09-29-merge-scenarios.md
Catalogs the many cases where multiple contact/group-member records refer to the same person and aren't merged (duplicate contacts on repeat invitation/contact-request connections, unmerged member records across groups, etc.), a consequence of the platform's lack of user identity. It proposes solving these mainly by extending the probe mechanism (probing group members when no associated contact exists, merging all confirming records rather than just the first), handling profile-address-based association cautiously, and fixing repeat group-link joins (open the group if it exists, else re-request invitation). It also suggests an opt-out "Merge contacts" setting to preserve profile privacy.

### docs/rfcs/2023-09-30-pq-double-ratchet.md
Proposes making SimpleX's double-ratchet (with header encryption) post-quantum resistant against record-now-decrypt-later attacks, while preserving forward secrecy, deniability, and break-in recovery. Unlike Signal's PQXDH (which doesn't protect break-in recovery) or Tutanota's scheme (which loses conventional-computer resistance/deniability), it augments rather than replaces DH by running PQ KEM(s) in parallel on each DH ratchet step (a "parallel ping-pong" with two KEMs in flight), suggesting NTRU-prime/sntrup761 (with CTIDH as an alternative). It includes full pseudocode and discusses SimpleX-specific implications: fixed 16KB padding absorbing the size overhead, key-size impact on invitation links, and slow PQ key generation limiting use in larger groups.

### docs/rfcs/2023-10-05-contact-merge-improvement.md
Addresses bugs in the existing contact-merge logic, where keeping both contacts' connections and selecting the "active" one by connection-id ordering can make the two sides pick different connections and break message delivery. It compares two solutions: not merging contacts at all (only merging members, simpler and stability-preserving but keeps split identity and requires reworking group links), versus improving the merge protocol with an `active_contact_conn` flag, created_at-based selection, and a new `XInfoProbeComplete` handshake so both sides subscribe to both connections until it's safe to delete the inactive one. It weighs the trade-offs of each.

### docs/rfcs/2023-10-12-desktop-calls.md
Solves how to make audio/video (WebRTC) calls on the new desktop client, comparing adapting Google's libwebrtc (too costly, needs many C++ devs), bundling a Chromium WebView (100+ MB bloat), or reusing the existing Android WebRTC HTML/JS via a local browser. It recommends the third option: run a local WebSocket signaling server in the app and open the existing (UI-augmented) WebRTC page in the user's default browser at a localhost URL, with no TLS needed for the local-only channel. This keeps package size small, reuses existing code, and enables future cross-platform screen sharing.

### docs/rfcs/2023-10-12-remote-ui.md
The implementation-details follow-up to the remote-profile RFC, defining the remote controller (desktop) and remote host (mobile) roles and the careful state handoff between local and remote control. It specifies the ordered steps for switching the mobile between local-UI and remote-host roles (gating event queues to avoid races), and lets the desktop control one active host while still receiving notifications from multiple connected hosts. It also covers core changes for connection-status tracking, a "remote-only" desktop via a phantom profile and reworked onboarding, and FFI/HTTP APIs for loading files on the desktop.

### docs/rfcs/2023-10-20-group-integrity.md
A more concrete (and terser) successor design for group integrity using three linked DAGs: an Owner DAG (profile/permissions, owner/admin changes), an Admin DAG (member invites/removals, linked to owner), and a Messages DAG (linked to both). It classifies every chat protocol event into owner/admin/message/none, sketches Haskell types and pseudocode for processing each DAG with conflict handling (consensus for owner events, "most destructive wins"/unconfirmed-change buffering for admin events, local-graph-then-correct for messages), and grapples with reverting failed events, malicious non-existent parents, and whether to replace the admin DAG with a BFT blockchain (judged impractical for asynchronous mobile groups).

### docs/rfcs/2023-10-24-robust-discovery.md
Hardens the remote-session discovery phase against UDP spoofing and platform issues found in the initial spike, and makes discovery a standalone service supporting multiple parallel announcers. It specifies an authenticated announce datagram (versioning, service address, CA fingerprint, X25519 DH key, Ed25519 signature) sent over the site-local multicast group 224.0.0.251 on port 5227, with matching OOB data (Ed25519 key, CA fingerprint, device name). It details the announcer (including discovering its own LAN address via multicast "Identify"/mirror datagrams), the listener's verification rules, dynamic-port services, and the controller/host connection step sequence.

### docs/rfcs/2023-11-21-inactive-group-members.md
Group traffic is wasted because clients keep sending messages to members who have gone silent or left without notice, exhausting SMP queues and triggering slow retries. The RFC proposes detecting inactivity (via QUOTA errors, QCONT events, and counters of unanswered sent/received messages) and suppressing sends to inactive members, plus protocol additions to notify suspended members of delivery gaps and to replay skipped message history (XGrpMemSuspended, XGrpMsgHistory). A 2024-02-12 update introduces a simpler alternative: periodic group-wide "pings" (XGrpPing) so members advertise their presence instead of relying on complex per-member counters.

### docs/rfcs/2024-01-04-members-profile-update.md
Profile updates (name, image, etc.) reach direct contacts but not group members, because broadcasting them to all member connections was too expensive, so group members see stale profiles. The RFC proposes tracking which members have received the latest profile update (via timestamps like user_member_profile_updated_at vs. a per-group sent_at) and sending a pruned profile (name/image only, excluding preferences and optionally contact link) when the user is next active in the group. It discusses whom to send to (skipping incognito groups), and whether to batch the update with the main message versus sending it separately.

### docs/rfcs/2024-02-12-database-migration.md
Migrating the database to another device is multi-step and error-prone, and every database operation confusingly requires manually stopping chat. The RFC redesigns the Database settings UX to guide users through single-tap, alert-driven flows for export, import, passphrase management, and especially device-to-device migration via XFTP upload plus a QR code/link (moving the stop-chat toggle to dev tools). Implementation leans on the new ability to upload/download XFTP files without messages and would require a second chat controller instance for the migration process.

### docs/rfcs/2024-02-13-inactive-group-members-2.md
A simplified successor to the 2023-11-21 inactive-members RFC, narrowing scope to reducing wasted group traffic. It proposes improving connection deletion (batching DB ops on leave/delete and fixing an agent race that drops pending messages), tracking a per-member inactive flag set on QUOTA errors and reset on QCONT/any message, suppressing sends to inactive members, and tracking skipped messages. It replaces the earlier history-replay machinery with a single XGrpMsgSkipped event announcing the first skipped shared message id and a skip count before the next message.

### docs/rfcs/2024-02-19-settings.md
A follow-up to the database-migration RFC: with the new UX auto-starting chat after import, users lose the chance to configure privacy/security settings (SOCKS proxy, auto-downloads, link previews) beforehand, so settings must travel with the migrated archive. The RFC weighs storing settings in the database versus a cross-platform JSON file in the archive, favoring the JSON-file approach, and proposes a core-maintained AppSettings type embedded in ArchiveConfig with a new ArchiveImportResult return type that surfaces imported settings (using defaults for any missing/invalid properties).

### docs/rfcs/2024-02-28-pq-integration.md
Covers integrating post-quantum encryption into the chat layer, addressing two gaps: group size being unknown when joining (needed because PQ is disabled for large groups), and communicating each conversation's encryption intent/state to users. It proposes conveying group size (e.g., in XGrpInv or a new XGrpIntro/XGrpInfo message) and adding non-merged "e2e encryption info" chat items that state a conversation is end-to-end encrypted and whether PQ is enabled, with concrete example texts for direct vs. group chats and rules for when to (re)create these items.

### docs/rfcs/2024-03-14-super-peers.md
Argues the current fully-connected p2p group design doesn't scale to large public groups/channels (connection cost, linear traffic, participation asymmetry) and lacks features like async delivery, hidden member lists, and pre-moderation. It proposes a new architecture modeled on Telegram channels where designated "super-peers" host the group as a Merkle-tree of content (allowing content removal as holes) and relay messages, with multiple super-peer addresses in the join link for censorship resistance. The bulk of the doc scopes an MVP: core group lifecycle, message delivery via super-peers, super-peer management protocol extensions, a multi-super-peer address format, and a permissions/management model, deferring extra super-peers and smart-contract governance.

### docs/rfcs/2024-03-22-communicating-reject.md
Many interactions (contact requests, group join requests, calls, group invitations) currently support only silent rejection, which is good for privacy but poor for usability when users don't mind signaling a decline. The RFC proposes optional rejection communication: a new AgentRejection envelope (reusing the deletion-with-pending-delivery mechanism) carrying encrypted rejection info for contact/group-join requests, plus new chat protocol events (XReject, XGrpReject with reason codes, XCallReject) for the other cases. It covers versioning so clients only offer notified rejection when the peer supports it.

### docs/rfcs/2024-04-01-super-peers-2.md
A detailed design follow-up to the super-peers MVP RFC, specifying concrete protocol mechanics for super-peer-hosted groups. It decides super-peer status is a function of any member with a role (adding rank/permissions fields to MemberInfo/MemberIdRole and a group "routing mode"/rank to GroupProfile), defines a probabilistic per-message delivery algorithm so each message is delivered by a target-redundancy subset of super-peers, and addresses authorizing administrative changes via signed actions (member authKeys), owner/admin consensus (GroupConsensus), and an orthogonal proposal/approval message layer (MessageStage, MemberApproval, MessageBroadcast with scheduling). It closes by selecting a minimal MVP scope (broadcasting via super-peers, channel-style comment/reaction-only groups) with the rest optional.

### docs/rfcs/2024-04-16-ip-address-protection.md
Senders' IP addresses are exposed to recipients' chosen SMP servers (and recipients' IPs to senders' servers for XFTP files), which is a privacy problem especially with self-hosted servers. For SMP, the RFC adds agent support for sending proxies plus a "Use SMP proxies" network setting (always/never/for unknown servers). For XFTP it defers proxying but adds an only_via_tor flag through the receive APIs so clients decide whether to auto-accept files, alert about unknown servers, or abort (new UNKNOWN_NO_PROXY error and CIFSRcvCancelledNoProxy status) when Tor is required but off; the previously considered "trusted servers" idea is dropped as too complex.

### docs/rfcs/2024-04-26-commercial-model.md
Argues SimpleX's two-tier network can achieve far greater decentralization than p2p but lacks a built-in incentive mechanism, so a large share of traffic still runs on SimpleX Chat Ltd.'s preset relays. Rejecting ad-based, crypto-token, and freemium models, it proposes that software vendors issue cryptographic "infrastructure certificates" to clients (some free, more sold) that clients spend as one-time micro-payments to provision resources (queues, proxy sessions, file chunks) from independent infrastructure operators, who then redeem them with the vendor. The design aims for extreme provider portability and zero operator control over user data; it notes downsides (dependence on vendor payment infrastructure, payment-to-operator correlation) and sketches zero-knowledge-proof and delegated-issuance mitigations, framing the certificates as gift-card-like rather than currency.

### docs/rfcs/2024-05-17-flexible-user-records.md
User records currently act as rigid containers where new conversations can only be created under the active user, but users want to choose a profile right at the connection screen. The RFC proposes letting the connect UI offer joining as any (non-hidden) user profile, then explores broader ideas to make user records feel like flexible tags: a dedicated "incognito" user profile uniting all incognito chats, forwarding messages between users, per-user network settings (requiring agent changes to a UserId-keyed network config map), a unified all-users chat list, and moving chats between profiles. Several of these (incognito migration, moving chats) are flagged as complex and possibly not worth the effort beyond an explanatory MVP.

### docs/rfcs/2024-06-17-agent-stats-persistence.md
Agent statistics are kept only in memory and lost on app restart, which hampers debugging user-reported bugs. The RFC proposes persisting stats periodically into the encrypted database (not plaintext, since keys include server names) and lays out four design options across two orthogonal axes: whether to store them in the chat DB or the agent DB, and whether the agent accumulates from prior sessions in memory or tracks only the current session with past stats stored separately. It includes table schemas for each option and discusses timely removal of deleted users' keys for privacy and accurate totals.

### docs/rfcs/2024-07-09-group-snd-status.md
The chat-item info UI doesn't distinguish sent from pending group messages, doesn't show why a message is pending (connecting vs. member inactivity), and doesn't account for messages awaiting admin forwarding. The RFC proposes adding richer group-send statuses, weighing extending the existing CIStatus/ACIStatus types (simple but mixes concerns) against introducing a dedicated GroupSndStatus type with values like forwarded, inactive, sent, received, and error. It favors the separate type for cleaner separation of concerns and future extensibility, at the cost of more work and backward-compatible decoding.

### docs/rfcs/2024-10-27-server-operators.md
Having all preset servers run by one company risks correlation of user connections by aggregating transport data, so the app should ship servers from more than one operator. The RFC proposes letting users assign operators to servers (preset and custom), recommending that roles be assignable only at the operator level for UX/logic simplicity, and requires users to explicitly accept each operator's conditions of use. Acceptance is recorded by storing the signature plus the agreement (or its hash/version) on the device, with the terms bundled into the app (compressed, ~31kb) rather than referenced externally.

### docs/rfcs/2024-11-28-business-address.md
Businesses need support-style conversations where a customer can talk to multiple identified people in the business (with transfer/escalation and bots), and customers may want to add friends/relatives, which no current messenger offers cleanly. The RFC proposes a "business mode" for contact addresses: requests are auto-accepted (with optional auto-reply), and each incoming request creates a dedicated group with the customer instead of a direct conversation, with the requester added as a member (promotable to admin). The group is presented specially (business name/avatar to the customer and vice versa, distinct icons for customer vs. business members), enabling support bots and human-agent escalation.

### docs/rfcs/2024-12-08-chat-bot-ui.md
Interacting with chat bots requires typing structured commands correctly, which is hard for most users. The RFC proposes two UX improvements: bots advertise a menu tree of supported commands via a chat preference, surfaced when the user types "/", inserting a chosen command (with `<name>` placeholders) into the compose field; and bots can send interactive button dialogues that render as selectable options whose chosen text is sent back (preferably as a normal reply). For the protocol it recommends bots send a plain-text message to old clients plus a structured `dialog` message-container property (with choices, layout, and an allow-free-text flag) to new clients, preserving backward compatibility.

### docs/rfcs/2024-12-28-reports.md
Group moderation is hard, especially with anonymous members and as groups grow, so members need a way to flag offensive/rule-violating messages to moderators. The RFC proposes a "Report" feature that forwards the reported message only to group moderators/admins (and the Directory bot), preferring a dedicated per-group "Reports" subview (showing the reported message, reason, and reporter, with actions to moderate, navigate to the message, or contact the reporter) over inline flags. For the protocol it weighs a dedicated `x.msg.report` event versus a backward-compatible message-quote with a new content type, favoring the quote approach because old clients can still render it, and it touches on a future comments feature for discussing reports.

### docs/rfcs/2024-12-30-content-moderation.md
Addresses how to keep moderating abuse (chiefly CSAM in public groups) as the network scales to large groups, given the current whack-a-mole approach of disabling group links and deleting files won't be sustainable. The core argument is that user actions can be restricted purely client-side—on both sending and receiving clients, like the existing 1GB file limit—without any user identification, so blocked groups can't keep functioning unless all participants run modified clients on self-hosted servers. It brain-dumps possible future measures (a server BLOCK command with reasons, client-side upload/messaging restrictions tied to blocking records on files and group links, reports to owners and third-party operators, server blacklisting) while stressing these are non-committal, applied only to CSAM-oriented groups, and designed to preserve privacy and avoid content scanning.

### docs/rfcs/2025-01-20-member-mentions.md
Addresses how to support @-mentions of members in group messages, covering notification, navigation to unread mentions/replies, and highlighting/tapping to open profiles. Proposes the familiar `@name` / `@'member name'` text format plus an embedded mapping array of `{displayName, memberId}` so mentions resolve to immutable member IDs (avoiding races and duplicate-name leaks), with a per-message limit (e.g. 3) enforced on both ends. Also specifies a paginated `@`-autocomplete API, UI/markdown handling, forwarding rules (substitute current display names, drop the mapping), and two new `chat_items` columns (`user_mention`, `member_mentions`).

### docs/rfcs/2025-02-13-super-peer-groups-mvp.md
Lays out a prioritized MVP plan for migrating SimpleX groups to a "super-peer" architecture to cut connection count and sender traffic by having designated highly-available members forward all messages instead of full mesh introductions. Proposes giving public groups a permanent identity via an owner-controlled "short link" (an SMP blob/XFTP file) that lists super-peer group links and owners' keys, plus protocols for creating groups, adding/removing/replacing super-peers (including single-super-peer handoff), member-profile accounting, and group statistics. Includes schema additions (`users.superpeer`, `group_members.superpeer`) and discusses abuse/censorship trade-offs.

### docs/rfcs/2025-02-17-member-send-limits.md
Addresses rate-limiting member message sending to prevent group abuse. Proposes a per-member `rateLimit :: Maybe MemberRateLimit` (defaulting to a windowed limit like 15 msgs/60s for regular members, none for owners/admins/moderators), overridable via `XGrpMemRestrict` and a new `APIRateLimitMember` command, with in-memory window tracking on both send and receive sides and a `CRGroupSendingLimited` event to block/unblock the UI. Discusses problems (subscription surges, window desync, downtime backlogs) and alternatives to dropping over-limit messages, such as delayed/parameterized ACKs that pause per-connection delivery rather than prohibiting messages.

### docs/rfcs/2025-03-07-group-knocking.md
Addresses screening ("knocking") of members before they are admitted to a group, improving on the v6.3 `acceptMember` hook so screening isn't limited to a single highly-available admin. Proposes that the group-link host initially introduce a pending member only to admins/approvers, forwarding messages during a per-pending-member screening conversation, and—upon acceptance—introduce the remaining members so connectivity no longer depends on admin availability. Suggests options for defining approvers (a new `Approver` role, an orthogonal member setting, or a communicated ID list), plus schema (`group_profiles.approval`), per-pending-member chat scopes, and special host handling of forwarded `XGrpLinkAcpt`.

### docs/rfcs/2025-04-14-signing-messages.md
Tackles two authenticity problems: proving ownership of addresses included in profiles, and preventing chat relays/super-peers from forging owner/admin roster actions in next-gen groups. The core focus is *how* to make JSON-encoded messages verifiably signable despite non-deterministic key ordering, weighing Option 1 (deterministic JSON re-encoding) against the preferred Option 2 (multi-stage encoding that frames the JSON body, a conversation binding, and `(key reference, signature)` tuples). Decides that only roster/group-management messages are signed—not content messages—to preserve deniability, since content forgery is detectable post-hoc via cross-relay consistency while roster changes are irreversible and must be authenticated at processing time.

### docs/rfcs/2025-07-30-channels.md
Defines the MVP scope for "channels" (large broadcast groups where only owners post and members are observers who can react), superseding the earlier super-peers RFC by narrowing it. The threat model centers on preventing chat relays from acting as owners, so channel identity is rooted in owner keys with owner-signed profile/ownership changes and a consensus protocol for owner changes. Scope includes relay-based message forwarding with cross-relay deduplication/difference-highlighting, making the group link part of the profile, SMP service-certificate subscriptions, Postgres migration, member keys, file re-uploading for indefinite storage, and content moderation; pagination, history navigation, e2e admin chats, and comments are post-MVP.

### docs/rfcs/2025-08-09-chat-widgets.md
Addresses how to support rich bot UIs (Telegram-style inline buttons) and interactive user "activities" (polls, doodles, mini-games) in the apps. Proposes "inline chat widgets" with a strict security/execution model: immutable code plus mutable state, where only user actions trigger sent messages and each peer can send only one state-update event until a user acts (preventing widget-to-widget loops and abuse), with options for who may participate in group widgets. For implementation it argues against general-purpose languages (hard to sandbox/taint) in favor of a constrained Lisp (PicoLisp run as a hardened library), with a widget library exposing predefined functions like `ButtonGrid` and `Poll`, and rendering via SVG/bitmap (or Nuklear).

### docs/rfcs/2025-08-11-channels-forwarding.md
Expands the channels RFC on relay message forwarding, addressing limitations of current forwarding (only during connection setup, single forwarding admin as SPOF, synchronous/non-resumable, doesn't scale to hundreds of thousands of members). Proposes that all chat relays forward all messages between owners and members continuously, with recipients deduplicating and highlighting cross-relay differences for trust, and replaces synchronous forwarding with persistent, resumable, batched, cursor-paginated asynchronous forwarding jobs. Includes a `forwarding_jobs` table and new `messages` columns, an optional sender-owner-hiding ("message from channel") flag making `MemberId` in `XGrpMsgForward` optional, special handling of connection-deleting events, and post-update ideas (profile delivery scheduling, batched reaction/comment counts, priority connections).

### docs/rfcs/2025-10-20-chat-relays.md
Specifies the group/channel chat-relay protocol and its security objectives: stable delivery, preventing relays from substituting the group, impersonating owners, altering the roster, or dropping/altering messages, while allowing owners to remove the last relay and restore the group. Provides detailed (Mermaid) protocols for adding relays (using a shared group ID baked into both group and relay link immutable data, owner-key-signed profiles, owner verification of relay links) and for removing relays and restoring group connectivity via new relays. Includes a threat-model analysis of single/colluding/partial compromised relays and a TODO list of chat commands, protocol processing, agent APIs, and UI work.

### docs/rfcs/2025-10-23-vouchers.md
Proposes the cryptographic design for "SimpleX Vouchers"—unlinkable tokens enabling private payments for server capacity within the commercial model. It defines a Coordination Layer (trusted party or ledger/smart contract), issuing and accepting operators, vouchers redeemable for blind-signed per-operator "AO credits," and works up an abstract protocol from a Chaumian-eCash-style v0.1 (with blind signatures, double-spend checks, and expiry) to a v0.2 using zero-knowledge set-membership proofs over a Merkle-mountain-range with nullifiers (plus MMR rotation) so even the Coordination Layer cannot link voucher publishing to redemption. It analyzes unlinkability residuals (timing/IP), ZK trade-offs (SNARK vs STARK), and enhancements like distributed ledgers and TEE mixers/provers.

### docs/rfcs/2025-11-17-async-commands-acks.md
Addresses the problem that continuations for asynchronous agent commands can be permanently lost if execution fails (e.g. a crash), breaking connection establishment and auto-replies. Proposes persisting the relevant events in the agent (a new `event BLOB` column on `commands`) until chat acknowledges processing them, then replaying unacknowledged events on the next start of command processing. Notes only two event types currently need this (INV for `XGrpMemIntro` continuations and JOINED for auto-replies), adds an `ackCommandEvent` agent API and an idempotency requirement on chat continuations, and weighs saving all events vs. only the necessary ones.

### docs/rfcs/2025-11-24-member-relations-vector.md
Addresses the N² storage cost of maintaining per-member introduction records by migrating to a per-member byte "relations vector" indexed by member index. It reworks forwarding and introduction logic around relation states (`MRNew`, `MRIntroduced`, `MRIntroducedTo`, `MRConnected`) so admins forward only to introduced members and duplicate forwards/introductions (and concurrent-connect races) are avoided, illustrated with a multi-admin diagram. It specifies a two-stage migration (live background population of vectors with a transitional introductions-based fallback, then offline migration of remaining records) and notes a pre-existing introductions race it explicitly won't fix.

### docs/rfcs/2025-12-10-vouchers-2.md
A simplified successor to the 2025-10-23 vouchers RFC, reducing to a single credit type, supporting arbitrary voucher amounts with change, and using one fixed-size Merkle tree. It proposes a smart-contract "Community Voucher" system where vouchers are blinded commitments (amount, assigned flag, expiry) added to a fixed-depth Merkle tree, and assignments/redemptions use zero-knowledge proofs with nullifiers to prove consistency between old and new commitments without revealing them. It details data storage (time-bucketed deposits, homomorphically encrypted redemptions, time-bucketed nullifiers, multiple recent roots), the voucher lifecycle (issuance, ZK proof, assignment to a community, redemption to an operator, releasing expired deposits to the network), and open privacy questions about relay visibility and expiry rounding.

### docs/rfcs/2025-12-17-community-vouchers-faq.md
An unabridged FAQ (mirroring the public site) explaining the Community Vouchers commercial model rather than a technical spec. It covers the motivation (paying privately for server capacity vs. surveillance-funded "free" platforms), preliminary pricing/free-tier limits and the "active message recipient" billing concept, continued support for self-hosted servers, and how zero-knowledge proofs provide unlinkability of purchase and use on a public blockchain. It also addresses legal/regulatory framing (vouchers as restricted utility tokens, no pre-sale, Howey test), revenue sharing with operators based on identity/uptime/trust, smart-contract governance, and the choice of an EVM/Ethereum chain (for native ZK support and ERC-20 compatibility).

### docs/rfcs/2026-01-08-relays-new-member-connection.md
Addresses how a new member should reliably connect to a group's multiple chat relays, since a naive synchronous per-relay flow causes partial failures needing recovery/cleanup. It evaluates options for the "join connection" step (fully synchronous with recovery, first-relay-sync-then-async, or all-async) and for link fetches, recommending synchronous link fetches (with user retry on failure) followed by asynchronous relay connections that rely on the agent for retry, with the group becoming functional once at least one relay reaches JOINED. It also requires fixing an orthogonal issue: a single incognito profile must be created once and reused across all relays (so `connectViaContact` should accept an optional profile).

### docs/rfcs/2026-01-23-member-keys-plan.md
A detailed implementation plan for adding member signing keys and message signatures to prevent relay impersonation and roster manipulation in relay-based public groups, realizing Option 2 from the signing-messages RFC. It specifies a `MemberKey` (Ed25519) type carried in `MemberInfo`/`XMember`/`XGrpLinkMem` (keys fixed at join, stored per-group in `groups`/`group_members`, not in profiles), a new binary batch wire format that length-prefixes elements to preserve exact bytes (enabling signature verification of forwarded messages without re-encoding), and conversation-binding signature framing. It also introduces a new agent prepare/create connection API for single-roundtrip public-group creation with a signed `OwnerAuth` chain, lists the files, migrations, phased steps, the roster-only signing scope (content unsigned for deniability), version gating (v17), and hard-fail verification behavior.

### docs/rfcs/2026-02-10-member-support-voice.md
Addresses a specific bug: the directory bot's voice captchas are blocked by `prohibitedGroupContent` in groups that disable voice messages, so captchas fail in most real groups. It proposes a protocol-version-17-gated exemption allowing host/admin voice messages only to members in the approval (pending) phase within the member-support scope, with a core `Internal.hs` change and a directory-bot (`Service.hs`) change that checks the member's client version and group voice setting before offering/sending a voice captcha, falling back to text/image captchas for old clients. It includes the exact code edits, a behavior matrix, version-gating rationale, and test cases.

### docs/rfcs/2026-03-28-group-identity-binding.md
Addresses instability in how group message signatures bind to a group identity: using the link-derived `groupRootKey` breaks bindings when links/keys are rotated, while an arbitrary entity ID isn't self-authenticating. It proposes using `groupEntityId = sha256(genesisRootPubKey)`—set at creation, immutable, self-authenticating, stored as `linkEntityId` in the short link and `sharedGroupId` in the group profile—as the signature-binding identity. It deliberately defers validating `linkEntityId == sha256(rootKey)` on join for forward compatibility with future link rotation, while still validating link-vs-profile consistency and profile-update immutability, and lists done/remaining changes (agent API, link creation, profile field, joiner check, signature-prefix swap).

### docs/rfcs/2026-05-21-public-namespaces.md
Proposes "public namespaces"—censorship-resistant, human-readable names (TLD `.simplex`, e.g. `#privacy`) mapping to SimpleX channel/contact links—to replace unmemorable short links and resist domain seizure/router-level deletion. The design has three parts: a blockchain contract (an ENS fork on Ethereum mainnet with commit-reveal registration, length-based pricing, renewal/Dutch-auction expiry, reserved names, test-NFT gating, and SimpleX resolver fields for channel/contact links and admin metadata); an SMP protocol extension adding a `names` router role where name-capable routers run Ethereum light clients and clients resolve via two independent proxy→name-server paths (agreement = trusted); and UI integration covering `#name`/`:name` markdown, double resolution (name→short link→connection data), and on-chain-vs-profile verification.

## plans/

Dated and undated implementation/design plans for features and bug fixes.

### plans/2026-02-17-ios-channels-product-plan.md
Product plan for bringing Channels to iOS. Channels are one-to-many broadcast groups (technically a group with `useRelays = true`) where messages flow owner → chat relays → subscribers, solving the broadcast use case that regular N-to-N SimpleX groups handle poorly at scale. The plan specifies the iOS screens (chat list, channel messages/compose, channel creation, channel info, relay management, joining) and an implementation order.

### plans/2026-03-05-members-conn-errors.md
Fixes group members stuck forever in a "connecting" state when their connection handshake fails with a permanent error (e.g. `SMP AUTH`, `CONN NOT_ACCEPTED`), which today is only logged to the UI and discarded. Adds a `ConnError {connError :: Text}` constructor to `ConnStatus`, persisted in the existing `conn_status` text column as `"error <text>"` (no migration) and exposed via JSON, using `temporaryOrHostError` to classify which errors are permanent. On a non-temporary pre-handshake error it transitions to `ConnError` and notifies the UI.

### plans/2026-03-13-message-keys-forwarding.md
Completes signed-message support for relay groups/channels: signing messages when sending, persisting signatures, having relays preserve/forward original signatures intact, validating bindings, requiring signatures on admin events, and exposing verification status in chat items. Introduces a reconstructed (not-on-wire) signing binding via a single-byte binding tag plus a `MsgSigning` record carrying key material and binding data, building the signed payload from context known to both signer and verifier.

### plans/2026-03-21-text-size-markdown.md
Adds a `!- text!` markdown syntax for small gray text (legal disclaimers, secondary commentary, LLM reasoning). Adds a `Small` constructor to the `Format` type across Haskell core, iOS, and (implied) Kotlin, with parser/serialization/rendering changes and tests; old clients degrade gracefully by showing the raw text or falling to `Unknown`.

### plans/2026-03-29-desktop-text-selection.md
Implements cross-message text selection on desktop (Compose Multiplatform): click-and-drag selection with auto-scroll, selecting only message text (not timestamps/names/quotes/dates, Telegram-web-style), Ctrl+C and a copy button, and selection persistence across scroll. Models selection as two endpoints (anchor/focus index + character offset) managed by a SelectionManager holding selection state and pointer coordinates.

### plans/2026-03-29-initial-open-last-unread-block.md
Changes the initial chat-open scroll behavior so that instead of always jumping to the oldest unread message (forcing casual members through hundreds of backlog unreads), it lands on the "new" messages that arrived after the user's last interaction. Changes the `CPInitial` pivot in `getDirectChatAround'`/`getGroupChatAround'` to try `maxViewedItemId` (last viewed item in sort order) first, falling back to `minUnreadItemId`.

### plans/2026-04-01-agent-sign-for-address.md
Adds a new agent API `getConnLinkPrivKey` to retrieve a connection's short-link private signing key (`linkPrivSigKey`, stored on `RcvQueue` in the agent DB) so the chat layer can sign challenges itself with `C.sign'`. This is a prerequisite for the `APITestChatRelay` relay-verification flow. Implemented in simplexmq's `Agent.hs`.

### plans/2026-04-01-test-chat-relay-plan.md
Adds an `APITestChatRelay` command letting channel owners verify a relay is alive, reachable, and authentic before creating a channel. It fetches the relay's short-link data (validating SMP reachability and retrieving the relay profile) and runs an `XGrpRelayTest` challenge-response handshake proving the relay controls its address private key, returning the profile and result to the UI. No DB schema change; `UserChatRelay` changes from a `name :: Text` to a `relayProfile :: RelayProfile` field.

### plans/2026-04-02-desktop-voice-recording.md
Implements desktop voice recording (currently a `RecorderNative` stub) using the already-bundled vlcj. Captures from the default microphone via VLC with platform-specific MRLs (pulse/qtsound/dshow), transcodes to mono 16 kHz 32 kbps AAC/m4a to match Android, removes the desktop "in development" guard in the composer, and adds the macOS microphone-usage Info.plist entry.

### plans/2026-04-06-onboarding-cards-compose.md
Compose (Android/Desktop) implementation of the onboarding cards feature, following the cross-platform layout spec in the iOS plan. Adds a new `OnboardingCards.kt`, eight stub card SVG assets, and shared `shouldShowOnboarding()` logic in `ConnectOnboardingView.kt` used from both the chat list and `App.kt`. Scope: the two paged screens with modal sheets, no banner or standalone variants.

### plans/2026-04-06-onboarding-cards-ios.md
Authoritative cross-platform layout specification plus the iOS implementation plan for onboarding cards. Defines two paged screens ("Talk to someone", "Create your link"), each with a title and two tappable cards that open deeper views (1-time link, connect via link, SimpleX address) as modal sheets, with detailed portrait/landscape layout, header, and padding rules.

### plans/2026-04-10-relay-leaving-group.md
Gives relay operators the ability to make their relay leave a channel group (a moderation capability for prohibited content), which currently fails because `getRecipients` uses `getGroupRelayMembers` that excludes the owner. Fixes the flow so the leaving relay sends `XGrpLeave` directly to owners and all subscribers, the owner updates the relay's status to a new `RSInactive` and republishes channel link data excluding the left relay, and subscribers drop the connection.

### plans/2026-04-11-channel-invitations-directory.md
Lets channel/public-group subscribers invite others by sharing a channel "card" (like forwarding a message) into any chat, with owners able to prove ownership via a signed card; this also unblocks directory listing for public groups. Old clients see plain text/link; new clients render a rich card with profile and a join button. Covers the owner-key/signature scheme (root key, `OwnerAuth` chain, `publicGroupId`) and the new card-based registration flow replacing admin-invitation.

### plans/2026-04-16-ios-share-channel-link.md
iOS UI for sharing a public-group/channel link as an `MCChat` card in any chat (backend already exists). Covers the send side (share entry points on channel info, a reused destination picker, a compose plaque), the wire/types (`LinkOwnerSig`, `OwnerVerification`), and the receive side (card rendering reusing the group-invitation tile, tap-to-connect via `planAndConnect` with owner-signature verification surfaced in the connect alert).

### plans/2026-04-17-kotlin-share-channel-link.md
Kotlin/Desktop port of the iOS "share chat card (MCChat)" feature (porting iOS commit `f49d98511`), mapping each iOS change to its Kotlin equivalent with file:line anchors. Adds `LinkOwnerSig`, an `ownerSig` field on `MCChat`, and a `chatLinkStr` helper in `ChatModel.kt`, then the corresponding send/receive UI.

### plans/2026-04-19-directory-public-groups.md
Enables directory-service registration of public groups (channels, and future group types) via signature-verified `MCChat` cards shared in DM with the directory bot, replacing the old admin-invitation flow. The bot verifies ownership through the `ownerSig`/`LinkOwnerSig` on the card (mapping `ownerId` to a group member) rather than needing to be added as an admin. Adds `GTGroup` to `GroupType` for forward compatibility.

### plans/2026-04-29-member-profile-sending-channels.md
Solves channel subscribers seeing "unknown member" for other subscribers' forwarded reactions/messages, without eagerly broadcasting all profiles (which won't scale to 100K+ subscribers). Relays store a per-member `sent_profile_vector BLOB` tracking which recipients already have which sender's profile, and prepend sender profiles (as `XGrpMemNew`) only to recipients who lack them when forwarding; a sender's vector is cleared on profile update. Steady state converges to near-zero redundant profile sends.

### plans/2026-04-29-relay-management.md
Adds the ability to add and remove relays on an existing channel (today relays can only be set at creation) and to keep relays/subscribers in sync. Adds an `APIAddGroupRelays` command (reusing the async `addRelays` flow) and extends `APIRemoveMembers` to mark the removed relay's `GroupRelay.relay_status` as `RSInactive`; implements the stubbed `runRelayGroupLinkChecks` and uses owner-published group link data so relays self-clean and subscribers connect/disconnect on open.

### plans/2026-04-29-relay-request-retry-limit.md
Fixes a denial-of-service vector where the single sequential relay-request worker retries indefinitely against an unreachable server, blocking all other channel setups. Following the XFTP worker pattern, it adds `relay_request_retries`/`relay_request_delay` DB columns, orders work by retry count (stuck items go last), caps consecutive retries per pickup with `withRetryIntervalCount`, persists/resumes backoff, and expires requests older than one day with 10+ retries.

### plans/2026-05-01-support-bot-list-api-pagination.md
Fixes the simplex-support-bot crashing on startup against large production databases with "Unknown failure", traced to `apiListGroups`/`apiListContacts` returning responses that exceed V8's ~512 MB max string length when marshaled through the N-API binding. Replaces the list-then-find-by-ID misuse patterns with pagination and direct lookups to keep payloads small.

### plans/2026-05-07-desktop-rtl-composer-fix.md
Fixes issue #4137: on desktop, typing RTL text (Arabic/Hebrew/Persian) in the composer while the system locale is LTR renders the first characters hidden under the send button, and misplaces the voice-preview/disabled `ComposeOverlay` text. The fix is in `PlatformTextField.desktop.kt`, correcting text-direction handling for the LTR-locale/RTL-text combination.

### plans/2026-05-07-fullscreen-viewer-wrong-image.md
Design doc for shipped PR #6869 fixing the desktop/Android fullscreen image viewer intermittently opening the chat's oldest media instead of the tapped image. Root cause was in the virtual-pager state model (`providerForGallery`) where `scrollToStart()` mis-locked the pager boundary depending on the runtime state of the immediately-older sibling of the tapped item.

### plans/2026-05-07-simplex-chat-python-design.md
Design for a `simplex-chat` Python 3 library on PyPI for building SimpleX bots, with the same capability as the existing Node.js library. Users write a script with decorator-registered handlers; the library wraps the prebuilt `libsimplex` native lib (loaded via ctypes), generates Python types from the Haskell type generator, and exposes an async public API. Covers architecture, type generation, native lib loading, distribution/CI, and testing.

### plans/2026-05-07-simplex-chat-python-implementation.md
Phased implementation plan for the Python library (companion to the design doc). Two work streams in the monorepo: extend the Haskell type generator (`bots/src/API/Docs/`) to emit Python types alongside TypeScript, and add a new `packages/simplex-chat-python/` package wrapping prebuilt libs via ctypes with lazy GitHub-release download and an async, decorator-based API. Eight ordered phases from type generation through CI publishing.

### plans/2026-05-08-desktop-text-selection-id-anchored.md
Fixes a bug in desktop text selection where `SelectionRange` stored positional indices into the front-growing `reversedChatItems` list, so a new/deleted message silently shifted the selection (and copy result) onto neighboring messages. The fix re-anchors selection on stable `ChatItem.id`s while recomputing positional indices on list mutation, so all downstream consumers (highlight, copy, snap, drag direction) stay correct.

### plans/2026-05-08-fix-select-in-reports.md
Design doc for PR #6863 fixing desktop copy of selected text in report items, which render as a red italic reason prefix plus the comment (e.g. `Spam: hi @alice`). Selecting `Spam: test` dropped the `Spam: ` prefix because offset walking started at body offset 0 while Compose returns display-space offsets that include the prefix. The fix starts the walk at `displayOffset = prefix.length`, emits the in-prefix portion, and extracts a single `itemPrefixText(ci)` source of truth.

### plans/2026-05-08-relay-announce-impl.md
File-and-symbol-level implementation guide (companion to the relay-announce overview) for the owner-pushed `XGrpRelayNew` event. Sequences the work into two PRs: a wire-format-only PR (Protocol.hs constructor/tag/JSON, `requiresSignature`, protocol docs) and a behavior PR (receive/send/forward), with each step keeping the build green.

### plans/2026-05-08-relay-announce.md
Overview plan for an owner-pushed `XGrpRelayNew` event so subscribers learn of newly added relays immediately, rather than only on the next channel open via `syncSubscriberRelays`. Defines the new JSON event (`x.grp.relay.new`) carrying a `ShortLinkContact`, the owner send site in the LINK callback (collecting relays that just transitioned to Active), relay forward-only handling, and reuse of the existing owner-signing infrastructure.

### plans/2026-05-09-desktop-tray-implementation.md
Implementation companion to the desktop-tray design: seven small, individually reviewable/revertable commits that build the tray feature incrementally while keeping the build green after each. Starts with a `CloseBehavior` enum and preference and includes pre-flight build verification on the `sh/tray` branch.

### plans/2026-05-09-desktop-tray.md
Adds a system tray icon (Windows notification area, Linux StatusNotifierItem, macOS menu bar) with opt-in "minimize to tray on close" behavior gated by a first-close dialog, a tray right-click menu (Show/Quit) with an unread indicator, and an Appearance settings toggle. Uses Compose Multiplatform's built-in `Tray`, probes `SystemTray.isSupported()` at startup and disables the feature entirely (hiding dialog/toggle) where unsupported (e.g. stock GNOME). All code lives in `desktopMain`.

### plans/2026-05-09-fix-image-text-overlap.md
Design doc for the Android/desktop fix (branch `nd/fix-image-text-overlap`) where a tall image's caption text was rendered overlapping the bottom of the image instead of below it, mirroring iOS PR #6732. The one-line fix in `CIImageView.kt` coerces the preview Box's `aspectRatio` to a floor of `1f/2.33f` so the layout (capped by `PriorityLayout`) no longer breaks.

### plans/2026-05-11-channel-owner-unlimited-delete.md
Lets channel owners delete their own content older than 24 hours (the existing time limit makes sense in p2p groups but not for an owner who is the authority over their channel). Rather than bypassing the limit for broadcast delete, it adds a new "delete from history" mode: within 24h, broadcast delete reaches subscribers and removes from relays; after 24h, history delete cleans only the relay store (subscribers keep their copies). Adds an `onlyHistory` field to `XMsgDel` and a `CIDMHistory` delete mode.

### plans/2026-05-11-fix-call-bind-port.md
Design doc for PR #6963 fixing desktop calls failing with `BindException: Address already in use` when the hard-coded WebRTC server port `localhost:50395` is busy. The fix makes the embedded NanoWSD server pick a free port instead of a fixed one. Desktop-only; Android uses an in-process WebView with no local server.

### plans/2026-05-11-link-tracking-whitelist.md
Design doc for PR #6965 fixing the "Remove link tracking" privacy setting incorrectly stripping whitelisted query parameters such as YouTube `?list=` (breaking playlist links) and GitHub `ref`. The bug is in the shared Haskell `sanitizeUri` (safe mode), where some branches consult the `qsWhitelist` of known-non-tracking params and others don't; affects iOS, Android, and desktop.

### plans/2026-05-12-link-trailing-underscore-exclamation.md
Design doc for PR #6973 fixing bare URLs/domains ending in `_` or `!` being highlighted as a clickable link only up to the last non-`_`/`!` character (e.g. a trailing `_` in a Wikipedia URL rendered as separate plain text). The fix is in `parseMarkdown`'s `wordMD`, which peels trailing punctuation off a "word"; it adjusts that peeling so `_` and `!` stay part of the link.

### plans/2026-05-13-desktop-single-instance.md
After tray support (#6970), the desktop app can stay alive in the tray holding the DB, so a second launch crashes on the SQLite lock or runs degraded. Adds single-instance behavior using two files in `dataDir`: a `simplex.started` lock file and a `simplex.show` signal file. A second launch creates `simplex.show` and exits; the running instance's `WatchService` detects it and restores/raises its window. Minimize-to-tray is only enabled when the lock is held.

### plans/2026-05-13-fix-group-link-share.md
Design doc for PR #6958 (Android/Desktop) fixing two failures in the channel-link "Share via chat" flow: picking Saved Messages as the destination returns a server error (`*<id>` has no branch in `sendRefP`), and the share button incorrectly renders on plain (non-channel) groups producing "not a public group". The fix filters Saved Messages out of the picker and gates the button on the source being a public group/channel.

### plans/2026-05-13-fix-privacy-links-import.md
Design doc for PR #6977 fixing the "Remove link tracking" toggle (`privacySanitizeLinks`) being silently lost when a chat database is exported/imported to another device. The setting was stored only locally and was missing from the `AppSettings` JSON record that travels with the DB. The additive fix adds `privacySanitizeLinks :: Maybe Bool` to `AppSettings` in the Haskell core, Kotlin, and Swift layers (wired like `privacyAskToApproveRelays`), with default false.

### plans/2026-05-13-relay-refuse-rejoin.md
Makes a relay refuse to rejoin a channel it previously left (preventing an owner from re-inviting a relay that has opted out). Reuses the existing `relay_own_status` column rather than adding storage: adds an `RSRejected` variant to `RelayStatus`, set when the relay leaves and checked at `xGrpRelayInv` (via the stored `groupLink`) before any DB write or network call. Includes careful state-machine handling so `RSRejected` isn't overwritten by inactive-cleanup or `xGrpMemDel`. Link rotation by the owner bypasses refusal (deferred to follow-up).

### plans/2026-05-14-fix-group-link-share-ios.md
iOS counterpart to PR #6958, fixing only bug #1: the channel-link "Share via chat" picker offers Saved Messages, which produces a server error because `sendRefP` has no `*` (local) branch and sharing to one's own note folder isn't meaningful. The fix filters `ChatInfo.local` out of `filterChatsToForwardTo` for this flow. Bug #2 doesn't exist on iOS, which already gates the share button on `publicGroup != nil`.

### plans/2026-05-15-fix-video-preview-snapshot-hang.md
Design doc for PR #6983 fixing desktop video playback where the second and subsequent videos in a chat never start (the first plays fine), which appeared after PR #6924 switched the preview helper to a dedicated `vlcPreviewFactory` with `--avcodec-hw=none`. Two compounding defects in `VideoPlayer.desktop.kt` (surfaced once hardware decoding no longer masked them) cause a snapshot stall to hang subsequent playback. Desktop-only.

### plans/2026-05-16-desktop-updater-fixes.md
Fixes the desktop in-app updater (`AppUpdater.kt`) failing on three of four platforms: Windows (no dialog ever, because an unconditional `which dpkg` call throws `IOException` that's swallowed), x86_64 AppImage (`xdg-open` opens the downloaded AppImage in an archive viewer instead of installing), and aarch64 AppImage (no dialog). macOS and `.deb` flows are unaffected. Fixes include guarding the Debian probe to Linux only and using the correct install operation for AppImages.

### plans/2026-05-20-fix-copy-non-msg-items.md
Design doc for PR #6993 fixing desktop text selection that, when a selection spans chat event/info items (connected, joined/left, call, e2ee-info, feature-change lines), copies those items' text into the clipboard even though they're never shown highlighted. Beyond the cosmetic issue, this is a privacy/metadata leak because event text is localized in the user's chosen UI language. The fix makes `SelectionManager.getSelectedCopiedText` skip non-message items when building the copied string.

### plans/2026-05-25-channel-web-preview.md
Adds a public web preview for SimpleX channels (like Telegram's `t.me/s/...`) showing the last ~50 messages so prospective subscribers can browse before joining. A new web-preview thread in the relay-mode CLI periodically loads publishable groups, renders JSON files served by Caddy (with CORS control), and regenerates the Caddy config. Integrates with the `.simplex`/ENS-based `groupDomain` namespace, with on-chain domain verification deferred until the RSLV resolution protocol ships.

### plans/2026-05-29-fix-space-in-interface.md
Fixes `/start remote host` failing with `Failed reading: empty` when the chosen network interface name contains a space (e.g. Windows `Ethernet 2`) on the "Link a mobile" screen. The `rcCtrlAddressP` parser's `jsonP <|> text1P` mis-parses a quoted iface name followed by `port=`. The fix replaces `jsonP` with a bounded `quotedP` that consumes only the quoted bytes and leaves trailing fields, with a regression test in `RemoteTests.hs`.

### plans/audio-captcha-improvements.md
Improves the directory-service audio captcha: adds a `DCCaptchaMode CaptchaMode` constructor to the `DirectoryCmd` GADT with proper Attoparsec parsing; makes audio-captcha retries actually send a voice (not image) captcha once the user switches to audio mode; and makes the `/audio` command clickable in the chat UI via `/'audio'` formatting.

### plans/channel_message_bugs_fix_plan.md
Fixes five channel-message-handling bugs in the core: delivery-context flag using `isChannelOwner` instead of the item's `showGroupAsSender` (critical); reactions allowing a missing member and falling back to membership; an update fallback default; a forward-API parameter bug; and a hardcoded CLI forward value. Includes a test plan and implementation order.

### plans/chat-relays-mvp-launch-plan.md
Launch plan for the Chat Relays MVP that enables large public channels (owner → relay → members instead of N-to-N). Inventories what's done (backend ~75%: delivery, forwarding, dedup, relay invitation/acceptance, relay-group creation) versus remaining (member key signatures, relay identity validation, forward-envelope protocol, UI on both platforms ~15%), with dependency summary, risk register, decisions, and a post-MVP backlog (relay removal/recovery, health monitoring, relay-to-relay sync, multi-owner, etc.).

### plans/deduplication-channel-messages.md
Code-cleanup plan to deduplicate the parallel channel-specific message functions a prior PR introduced, which duplicate 60–80% of the existing group functions (channel messages are essentially group messages with no member sender). Ranks high-value merge targets (e.g. `channelMessageUpdate_` into `groupMessageUpdate`, sharing helpers for reactions and new content) by feasibility and shared lines, with an architectural note on the `CIChannelRcv` constructor and an implementation order.

### plans/delivery-context-fix.md
Fixes the channel-message delivery architecture on branch `ep/channel-messages-2`, which wrongly determines whether to forward a message as channel-vs-member from `isChannelOwner` (the sender's role) instead of from the item's direction (`CIChannelRcv` vs `CIGroupRcv`), as the `f/msg-from-channel` branch does correctly. Spans 7 changes across 7 files, including a new `DeliveryTaskContext` type in Delivery.hs, removing `memberForChannel`/`memberIdForChannel`, fixing reaction/update lookups, and correcting two tests.

### plans/directory-tests-coverage.md
A test-coverage report (not a forward-looking plan) for the directory-service modules, recording final per-module expression coverage (Captcha/Search/BlockedWords at 100%, Listing lowest at 58%) after adding 84 passing tests to `tests/Bots/DirectoryTests.hs`. Documents what was newly covered, such as `SearchRequest` selectors and `BlockedWordsConfig` edge cases.

### plans/group_channel_feature_coverage.md
Test-coverage analysis and plan for group and channel features, noting the existing `Groups.hs` suite covers 120+ scenarios across 14 categories with core functionality well-tested. Identifies gaps (business/contact-card group links, legacy auto-accept link path, `SGFFullDelete` permission enforcement, error-recovery paths, moderator-only scoped delivery) and recommends new tests with a roadmap.

### plans/groups_coverage_fill_plan.md
Concrete plan to fill the group/channel coverage gaps identified in `groups_test_coverage.md`, using only DSL-based scenario tests on existing infrastructure (`tests/ChatTests/Groups.hs`), explicitly excluding JSON serialization tests. Prioritizes critical channel paths (P0), error/fallback paths (P1), scope-related features (P2), and feature restrictions (P3), e.g. non-owner members sending in channels and channel moderation/delete paths.

### plans/groups_test_coverage.md
A coverage-analysis report from running all ~164 group tests with coverage enabled, summarizing low overall numbers (48% expressions, 33% alternatives, 34% top-level). Lists which channel-specific paths are covered (e.g. `createNewRcvChatItem` with `CDChannelRcv`, channel sender validation) to seed the follow-up gap-filling plans.

### plans/website-file-page-implementation.md
Implementation plan for a `/file` page on the SimpleX website letting users upload/download files via XFTP directly in the browser as a live privacy demo funneling toward the app download. Reuses the pre-built `@shhhum/xftp-web@0.8.0` `dist-web/` bundle (three files copied to static assets, no Vite/TS build), wrapped by an 11ty page providing the protocol overlay, download CTA, and i18n bridge.

### plans/website-file-page-product.md
Product plan for the website file-transfer page, framed primarily as a conversion point to drive app downloads via a live in-browser demo of XFTP's privacy (browser-side encryption, no accounts/identifiers, decryption key in the URL fragment). Covers the conversion funnel, why XFTP is highly private, page/UX structure, upload/download flows, edge cases, abuse/moderation, and explicit non-goals.

## apps/simplex-support-bot/plans/

### apps/simplex-support-bot/plans/20260207-support-bot.md
Product specification for a SimpleX Chat support bot where customers connect via a business address into a private group to ask questions, and the bot triages through AI (Grok) or human team members. The team monitors all active conversations as cards in a single dashboard group rather than via forwarded text. Defines principles, user and team flows, architecture (CLI, bot, Grok integration), and persistent state.

### apps/simplex-support-bot/plans/20260207-support-bot-implementation.md
Implementation plan for the support bot as a standalone Node.js app using the `simplex-chat-nodejs` native NAPI binding. A single `ChatApi` instance runs two user profiles (main "Ask SimpleX Team" bot plus a "Grok" agent) sharing one SQLite database, with a `profileMutex` serializing all profile-switching and SimpleX API calls. Implements the Welcome → Queue → Grok/Team-Pending → Team flow and surfaces conversations as dashboard cards (no text forwarding).

## blog/

### blog/README.md
The index/landing page for the SimpleX Chat blog, listing all posts in reverse-chronological order from the most recent (v6.4.1, Jul 2025) back to the original 2020 announcement. Each entry links to a post and summarizes its headline features, covering the project's full release history (v0.4 through v6.4.1), security audits (Trail of Bits), funding news (Jack Dorsey/Asymmetric), and privacy advocacy essays. It serves as the navigational table of contents for the entire blog.

### blog/20201022-simplex-chat.md
The very first announcement (Oct 22, 2020), introducing the prototype of the SimpleX Messaging Server implementing the SMP (SimpleX Messaging Protocol). Written as a Reddit/r/haskell post seeking feedback, it describes a minimalist Haskell implementation defining just 7 commands and 5 responses over TCP to operate encrypted message queues with in-memory STM persistence. At this stage it is purely a low-level protocol demo plus a website explaining the chat idea, not yet a usable chat app.

### blog/20210512-simplex-chat-terminal-ui.md
Announces the first working SimpleX Chat prototype (May 12, 2021): a terminal/console client (v0.3.1) for Linux, Windows, and Mac, built by Evgeny Poberezkin and his son over six months. Key features include double-layer-free end-to-end encryption with MITM protection via out-of-band invitations, no global identity or usernames visible to servers, per-connection RSA message signing, message integrity validation, and encrypted TCP transport. A demo SMP server is pre-configured so users can try it without self-hosting.

### blog/20210914-simplex-chat-v0.4-released.md
Announces SimpleX Chat v0.4 (Sep 14, 2021), an open-source decentralized terminal chat using a privacy-preserving message-routing protocol with no central server and an invisible network graph. The headline new features are chat groups (created and managed via console commands, stored only as member lists in the local DB rather than on any server) and file transfer between contacts. The app is still terminal-based with mobile apps "in the pipeline" and is noted as early-stage development.

### blog/20211208-simplex-chat-v0.5-released.md
Announces SimpleX Chat v0.5 (Dec 8, 2021), still a terminal app, billed as the first chat platform that is 100% private by design with no access to the user's connections graph. The headline new feature is long-term chat addresses: reusable addresses that can be shared widely (e.g., in an email signature) so anyone can send a connection request. It is an ALPHA feature with no spam protection yet, but addresses can be deleted and recreated freely without losing existing connections.

### blog/20220112-simplex-chat-v1-released.md
Announces SimpleX Chat v1 (Jan 12, 2022), a major milestone declaring a stable, forwards/backwards-compatible protocol and addressing design issues found in an independent concept review. Encryption was re-engineered to add forward secrecy and break-in recovery: double-ratchet E2E with AES-256-GCM and X3DH/Curve448 key agreement, plus a separate per-queue DH (Curve25519/NaCl crypto-box) layer and additional server-to-recipient encryption to prevent traffic correlation. It also upgraded authentication/transport (ephemeral Ed448 keys, TLS 1.2+ with forward secrecy, server-identity fingerprint validation, tls-unique channel binding) and switched to efficient binary protocol encodings, cutting overhead from ~15% to 3.7%.

### blog/20220214-simplex-chat-ios-public-beta.md
Announces the first public beta of the SimpleX Chat iOS app via TestFlight (Feb 14, 2022) for iPhones on iOS 15. The app is very basic at this point, supporting only text messages and emojis, but it shares the same battle-tested Haskell core as the terminal app and provides the full v1 privacy/security guarantees (double-ratchet E2E, per-contact keys, additional queue and delivery encryption). It invites users to test and vote on which features (images, link previews, etc.) to prioritize for the March public release, with an Android app coming in a few weeks.

### blog/20220308-simplex-chat-mobile-apps.md
Announces the public release of both iOS and Android mobile apps to the App Store, Google Play, and as a direct APK (Mar 8, 2022), reusing the stabilized Haskell terminal core. Founder Evgeny explains the motivation: protecting users' connection graphs to shield people in oppressive regimes (citing the Russia-Ukraine conflict), since even Signal can be compelled to reveal contact graphs. It restates the v1 privacy model and previews upcoming features: push notifications, encrypted WebRTC audio/video calls, database export/import, message replies, localization, configurable servers, and image/file sending.

### blog/20220404-simplex-chat-instant-notifications.md
Details the design of private instant notifications (Apr 4, 2022) following ~2000 downloads after the mobile launch. For Android, they "cracked it" using a background/foreground service (modeled on ntfy.sh) that keeps TCP connections to messaging servers open, delivering instant notifications without sharing any device token, shipped in app v1.5. iOS, being more restrictive, requires Apple's push service, so they describe a forthcoming privacy-preserving notification-server design that subscribes to queue notifications via separate addresses and keys, never seeing message content or sender identities. The post frames this as a deliberate privacy/convenience trade-off and solicits feedback.

### blog/20220511-simplex-chat-v2-images-files.md
Announces SimpleX Chat v2.0 (May 11, 2022), whose headline feature is sending images and files privately in the mobile apps using privacy-preserving system file pickers (no broad gallery/file permissions, unlike Signal/Telegram). It notes this required a breaking core change, so both contacts need v2.0 to exchange files. The post also re-explains how SimpleX delivers messages without any user identifiers, instead using per-contact message-queue identifiers and 2-layer E2E encryption, and previews planned queue rotation so even conversations won't have long-term network identifiers.

### blog/20220524-simplex-chat-better-privacy.md
A small release announcing SimpleX Chat v2.1 (May 24, 2022) focused on better conversation privacy. The headline feature is the ability to clear conversations and irreversibly delete individual messages without having to delete the contact (previously the only option), letting users keep a connection while wiping its message history. It references the v1 and v2 posts for the underlying security and platform design.

### blog/20220604-simplex-chat-new-privacy-security-settings.md
Announces SimpleX Chat v2.2 (Jun 4, 2022), introducing a set of new Privacy and Security settings. These include SimpleX Lock (biometric/PIN authentication to reopen the app after 30s in background), disabling automatic image downloads to save data and avoid revealing you're online, and disabling outgoing link previews to avoid exposing your IP to linked websites. It also explains message-integrity tracking (each conversation acts as two private "blockchains" via sequence numbers and previous-message hashes) that flags lost messages, and teases experimental features in testing.

### blog/20220711-simplex-chat-v3-released-ios-notifications-audio-video-calls-database-export-import-protocol-improvements.md
Announces SimpleX Chat v3 (Jul 11, 2022) with four headline features: instant push notifications for iOS (via a privacy-preserving notification server that never sees queue addresses, sender identities, or message content); end-to-end encrypted WebRTC audio/video calls keyed through the existing chat connection; database export/import to move a chat profile between devices and platforms (with the caveat that a profile can't run on two devices at once and the archive is not yet encrypted); and protocol privacy/performance improvements (removing message timestamps from TLS and a faster, lighter connection-establishment flow, all backward compatible). The post also restates SimpleX's "no user identifiers of any kind" privacy thesis and appeals for donations toward a third-party security audit.

### blog/20220723-simplex-chat-v3.1-tor-groups-efficiency.md
SimpleX Chat v3.1-beta announcement, focused on efficiency and access improvements. Headline features: terminal app access to messaging servers via SOCKS5 proxy (e.g., Tor), the ability to join and leave chat groups in the mobile apps, optimized battery and traffic usage (up to a 90x reduction), and two Docker configurations for self-hosting SMP servers.

### blog/20220808-simplex-chat-v3.1-chat-groups.md
The stable v3.1 release announcement. Its headline feature is fully decentralized "secret" chat groups in the mobile apps (groups that only members know exist, with no server-side group identifiers), plus access to messaging servers via Tor, advanced network settings, a published chat protocol, and new app icons, carrying over the v3 battery/traffic optimizations and Docker server configs.

### blog/20220901-simplex-chat-v3.2-incognito-mode.md
SimpleX Chat v3.2 release introducing Incognito mode, a feature described as unique to SimpleX that shares a different randomly generated profile name with each new contact to eliminate shared data between them. Other additions include assigning local names to contacts, using .onion server addresses with Tor, endless scrolling and search in chats, accent color and dark mode, per-contact/group notification muting, and Android swipe-to-reply plus a major APK size reduction (200MB to 50MB). It also announced an upcoming October security audit.

### blog/20220928-simplex-chat-v4-encrypted-database.md
The major v4.0 release whose headline feature is encryption of the local chat database with a user passphrase. It also adds support for self-hosted WebRTC ICE servers, improved stability when creating new connections (more reliable groups, files, and contacts), deleting files and media, a TypeScript SDK for developers building chat bots/assistants, animated images on Android, and a German UI translation.

### blog/20221108-simplex-chat-v4.2-security-audit-new-website.md
This post announces the results of a security assessment of the simplexmq library (SimpleX's crypto and networking layer) by Trail of Bits, alongside a new website and the v4.2 release. The audit found 2 medium and 2 low severity issues (all high-difficulty to exploit), with 3 already fixed in v4.2; the medium issues included a flaw in the X3DH key exchange key derivation. v4.2 also adds manual queue rotation among other fixes.

### blog/20221206-simplex-chat-v4.3-voice-messages.md
SimpleX Chat v4.3 release, headlined by instant voice messages (sent without recipient acceptance, capped at ~92.5KB / roughly 30-42 seconds in MP4AAC). It also adds irreversible deletion of sent messages for all recipients, improved SMP server configuration with support for server passwords, and privacy/security improvements such as protecting the app screen in recent apps, blocking screenshots, optional Android data backup, and optionally allowing direct messages between group members. The post also rounds up favorable third-party reviews following the Trail of Bits audit.

### blog/20230103-simplex-chat-v4.4-disappearing-messages.md
SimpleX Chat v4.4 release introducing disappearing messages, which (unlike most messengers) require agreement from both sides and delete from sender and recipient devices after a set time. Other features include "live" messages that update for recipients in real time as you type, connection security verification, animated images and stickers (now on iOS too), and a new French interface translation.

### blog/20230204-simplex-chat-v4-5-user-chat-profiles.md
SimpleX Chat v4.5 release, headlined by support for multiple chat profiles managed within a single app (unlimited profiles, all connected simultaneously, with per-profile servers, message retention, contact address, and preferences). Additional features include message drafts, transport isolation, reduced battery usage, and private filenames, plus a new Italian interface translation.

### blog/20230301-simplex-file-transfer-protocol.md
This post introduces the SimpleX File Transfer Protocol (XFTP), a new protocol for sending large files efficiently, privately, and securely, with the CLI and relays implementing it released for immediate use. Files are split into encrypted chunks distributed across relays that have no file metadata; recipients use a "file description" to retrieve and reassemble chunks, files can be sent to multiple recipients, and chunks expire/delete after 48 hours. The article covers a quick-start CLI guide, the problem being solved, why existing solutions were unsuitable, how XFTP works, and future plans (integrating XFTP into the chat apps).

### blog/20230328-simplex-chat-v4-6-hidden-profiles.md
SimpleX Chat v4.6 release whose headline feature is hidden chat profiles, which are invisible in the app and show no notifications until a correct passphrase is entered (chosen over an app-wide PIN). It also adds ARMv7a (32-bit) and Android 8+ support (doubling supported devices), group/community moderation, group welcome messages, improved audio/video calls, reduced battery usage, and SMP server monitoring (status bot and page), plus new Chinese and Spanish interface languages.

### blog/20230422-simplex-chat-vision-funding-v5-videos-files-passcode.md
This post combines the v5.0 release with a discussion of SimpleX Chat's vision and funding (why it is a commercial company, its business model, and pre-seed funding from angel investors and Village Global). The v5.0 headline features are sending videos and files up to 1GB (via XFTP), an app passcode independent from system authentication, and networking improvements. It also adds a Polish interface, bringing the apps to 10 languages.

### blog/20230523-simplex-chat-v5-1-message-reactions-self-destruct-passcode.md
SimpleX Chat v5.1 release introducing message reactions (limited to 6 emoji, up to 3 per message) and a self-destruct passcode. It also improves messaging with voice messages up to 5 minutes, custom disappearing-message timers, and message editing history, plus a new design with customizable, shareable color themes and various smaller fixes; new Japanese and Portuguese (Brazil) interface languages were added.

### blog/20230722-simplex-chat-v5-2-message-delivery-receipts.md
SimpleX Chat v5.2 release, headlined by message delivery receipts with per-contact/per-profile opt-out (enabled by default for new profiles). It also adds filtering of favorite and unread chats, more usable groups (viewing full replied messages, sharing your address via profile, member search), stability improvements (connections surviving backup restore, more reliable address switching and delivery), better disappearing messages, and the ability to prohibit reactions; the post also discusses the limitations of public groups and the rationale around read receipts.

### blog/20230925-simplex-chat-v5-3-desktop-app-local-file-encryption-directory-service.md
SimpleX Chat v5.3 (Sept 2023) introduces the first multiplatform desktop app for Linux and Mac, requiring a new profile since there are no user accounts. Other headline features are a group directory service for searching public groups, encrypted local files and media with forward secrecy (per-file keys), and a simplified incognito mode. The release also cuts memory usage by 40%, adds privacy settings, fixes group connection and playback bugs, and ships six new interface languages.

### blog/20231125-simplex-chat-v5-4-link-mobile-desktop-quantum-resistant-better-groups.md
SimpleX Chat v5.4 (Nov 2023) lets you use your mobile chat profiles from the desktop app by linking the two devices over the same local network via a secure, quantum-resistant protocol (QR-code pairing with session-code verification and faster multicast reconnection). It also delivers much-improved groups: faster, more reliable joining and delivery, incognito group profiles, member blocking, and the ability to prohibit files and media. Calls are improved with faster connection and desktop screen sharing, plus smaller fixes like spaces in profile names.

### blog/20240124-simplex-chat-infrastructure-costs-v5-5-simplex-ux-private-notes-group-history.md
This post announces free infrastructure from Akamai/Linode (via the Linode Rise startup program, up to $10,000/month for year one, plus a Linode Marketplace listing and high-capacity server work) and releases v5.5 (Jan 2024). New features are Private Notes (locally stored, encrypted self-messages accessible from desktop), group history for new joiners, and a simpler UX for connecting to other users. The release also improves message delivery stability and adds Hungarian and Turkish, bringing Android to 20 languages.

### blog/20240314-simplex-chat-v5-6-quantum-resistance-signal-double-ratchet-algorithm.md
This is a deep technical post for the v5.6 beta (Mar 2024) on adding post-quantum resistance to the Signal double ratchet algorithm. It explains why end-to-end encryption matters, covers the history of encryption regulation and DJB's cryptography, and walks through six classes of attacks on E2E encryption and their mitigations (padding, deniability, forward secrecy, break-in recovery, two-factor key exchange, and post-quantum crypto against "record now, decrypt later"). It compares encryption security across messengers and explains when users can start using quantum-resistant chats, with direct chats, small groups, and a security audit planned next.

### blog/20240323-simplex-network-privacy-non-profit-v5-6-quantum-resistant-e2e-encryption-simple-migration.md
This post pairs the stable v5.6 release (Mar 2024) with strategy on combining a profitable business with non-profit protocol governance, arguing community and business interests are aligned and announcing plans to eventually transfer protocol governance to non-profit entities. It also welcomes privacy advocate Esra'a Al Shafei to the team to lead that governance effort. The v5.6 features are quantum-resistant E2E encryption (beta, opt-in for new contacts), the ability to use the app during audio/video calls, and migrating all app data to another device via QR code.

### blog/20240404-why-i-joined-simplex-chat-esraa-al-shafei.md
An opinion/personal essay (Apr 2024) by Esra'a Al Shafei explaining why, after a career in non-profits (Wikimedia, Access Now, Tor), she joined the VC-funded SimpleX Chat. She describes scrutinizing its $350K Village Global funding and concluding that a transparent, fully open-source, decentralized, values-aligned company can sustain privacy work where non-profits struggle for funding. She frames her role as helping move SimpleX's protocol governance toward non-profit stewardship, arguing transparency and open source matter more than the for-profit-vs-non-profit distinction.

### blog/20240416-dangers-of-metadata-in-messengers.md
An advocacy essay (Apr 2024) by Esra'a Al Shafei on the dangers of messenger metadata, arguing that phone-number-based identifiers tie messaging to biometrics and government-controlled telecoms. It uses WhatsApp's own app-store disclosures to show how much metadata (location, contacts, group membership, usage patterns, device IDs) is collected even with E2E encryption, and how aggregated metadata builds incriminating profiles and social graphs. It urges readers to consider their threat models and choose ID-free private alternatives, noting the messaging app you choose implicates everyone in your network, not just yourself.

### blog/20240426-simplex-legally-binding-transparency-v5-7-better-user-experience.md
This post introduces "legally binding transparency" (new Transparency Reports, FAQ, and Security Policy pages, plus a Privacy Policy update removing vague terms) and releases v5.7 (Apr 2024). The release extends quantum-resistant E2E encryption to all contacts, adds forwarding and saving messages without revealing the source, in-call sounds and switchable audio sources, better network connection management, and customizable profile image shapes. It also notes v5.7 lays groundwork for v5.8's built-in IP-address protection and adds Lithuanian.

### blog/20240516-simplex-redefining-privacy-hard-choices.md
An essay (May 2024) explaining the deliberate, sometimes inconvenient choices behind SimpleX's privacy model. It covers having no user accounts or profile identifiers at the protocol level, prioritizing privacy over convenience (cautious multi-device support citing a Signal Sesame vulnerability, and avoiding third-party push notifications), and choices around network decentralization. It also defends SimpleX's per-file encryption and forward secrecy, contrasting with Session's removal of forward secrecy and Signal's trade-offs.

### blog/20240601-protecting-children-safety-requires-e2e-encryption.md
An advocacy post (June 2024) arguing that protecting children requires preserving, not weakening, end-to-end encryption. It opposes the EU's "upload moderation"/client-side scanning proposals (Belgian Presidency, EU CSAM) as mass surveillance that creates breachable central databases enabling blackmail and abuse, noting SimpleX signed a joint statement against them. As an alternative it advocates privacy-by-design models like SimpleX's, where users (or children) cannot be discovered or contacted without permission, and urges readers to lobby their representatives.

### blog/20240604-simplex-chat-v5.8-private-message-routing-chat-themes.md
SimpleX Chat v5.8 (June 2024) adds private message routing, an onion-routing-style scheme that protects senders' IP addresses from recipients' messaging relays without requiring Tor (which remains supported via SOCKS proxy). Additional features include server transparency, IP-address protection when downloading files and media, and chat themes for Android and desktop. The release also brings group improvements with reduced traffic and new preferences, better networking and delivery, and the Persian language.

### blog/20240704-future-of-privacy-enforcing-privacy-standards.md
An advocacy/policy essay (July 2024) arguing privacy should be a legally enforceable, non-negotiable duty of technology providers rather than a right users must defend. It criticizes surveillance capitalism, AI-driven data exploitation (Microsoft, Perplexity, Meta) and anti-privacy/client-side-scanning legislation in Europe, the US, and Australia, while praising legal action such as Noyb's complaints against Meta. It proposes privacy legislation establishing strict provider duties, banning consent-based data-sharing workarounds, and prohibiting collection of unnecessary data like phone numbers as a condition of access.

### blog/20240814-simplex-chat-vision-funding-v6-private-routing-new-user-experience.md
Announces a $1.3M pre-seed funding round led by Jack Dorsey with Asymmetric Capital Partners (following earlier Village Global investment) and a planned path toward non-profit governance. It also releases v6.0, with private message routing now enabled by default. Key UX features include a new "reachable" chat interface, faster connecting, contact archiving, bulk message moderation, chat themes, larger fonts, new media options (play from chat list, blur for privacy, share from other apps), and improved networking with reduced battery usage.

### blog/20241014-simplex-network-v6-1-security-review-better-calls-user-experience.md
Covers a July 2024 cryptographic design review by Trail of Bits of SimpleX's protocols (SMP, SMP agent, push notifications, XFTP file transfer, XRCP remote control, and chat protocol), which found no critical issues — only 3 medium, 1 low, and 3 informational findings, all hard to exploit, with several fixed in this release. It announces v6.1, headlined by better calls, better iOS notifications, and general user-experience improvements. A follow-up security audit is planned for early 2025.

### blog/20241016-wired-attack-on-privacy.md
An opinion/rebuttal post pushing back on a Wired article (by David Gilbert) that focused on neo-Nazis migrating to SimpleX after Telegram's policy changes, arguing the piece cherry-picks an ISD report and ignores SimpleX's metadata-minimizing design that protects journalists, activists, and ordinary users. It argues SimpleX's design actually hinders large extremist networks via restricted message visibility and file retention. The post strongly opposes client-side scanning and using private communications for monitoring or AI training, defending encryption and privacy as essential rights.

### blog/20241125-servers-operated-by-flux-true-privacy-and-decentralization-for-all-users.md
Announces that Flux — a decentralized cloud of user-operated nodes — now provides preset servers in the v6.2-beta.1 release, so users are no longer relying solely on SimpleX Chat-operated servers. Using two independent operators improves connection/metadata privacy, since the app will choose servers from different operators in each connection for receiving messages and private message routing. Flux servers are opt-in under the same privacy policy, and the post compares SimpleX's decentralization with Matrix, Session, and Tor.

### blog/20241210-simplex-network-v6-2-servers-by-flux-business-chats.md
The stable v6.2 release, bringing the Flux-operated preset servers (via an agreement with Influx Technology Limited) to all users to improve metadata privacy by using two operators per connection. It introduces business chats — a hybrid of one-to-one and group conversations that let customers see who they're talking to and let businesses add team members for delegation/escalation, with bot support coming. Other improvements include opening on the first unread message, jumping to quoted messages, seeing who reacted, and better iOS notifications.

### blog/20241218-oppose-digital-ids-they-break-law-lead-to-mass-scale-surveillance.md
An advocacy post opposing the UK government's plan to introduce digital ID cards (e.g., for age verification at pubs), arguing they normalize mass-scale surveillance, are ineffective at preventing law violations, and actually violate Article 8 of the European Convention on Human Rights. It warns that "optional" systems tend to become mandatory and that centralized identity databases increase the risk of financial and identity crime, citing China's social credit system as a cautionary example. It calls on readers to refuse digital IDs and provides a template email to send to their MP.

### blog/20250114-simplex-network-large-groups-privacy-preserving-content-moderation.md
A design/explainer post arguing that end-to-end encrypted conversations can be moderated without compromising privacy or encryption, countering the case for client-side scanning. It outlines plans to scale large groups using "super-peers" (dedicated members that re-broadcast messages) and to give group owners stronger anti-abuse tools — member reports (in the just-released beta), message comments, per-day message limits, pre-moderation, "knocking," and sub-groups. It also describes privacy-preserving server-side content moderation and previews planned privacy/security improvements for the year.

### blog/20250308-simplex-chat-v6-3-new-user-experience-safety-in-public-groups.md
The v6.3 release focused on safety in public groups, adding anti-spam/abuse measures including optional captcha verification (generated by the directory bot with no third party) and a profanity filter for member names, plus private reports to moderators. Group improvements include member mentions with notifications and better performance, while navigation gains chat lists and jump-to-found/forwarded messages. Privacy/security additions include per-chat message retention periods and private media file names; the release also adds Catalan and makes server builds reproducible.

### blog/20250703-simplex-network-protocol-extension-for-securely-connecting-people.md
A technical post (shipping in v6.4-beta.4) introducing a protocol extension — short links with associated queue data — that overhauls the connection experience so you can start talking as soon as you scan a link. It solves the old problems of long, "scary," easily-mangled links and QR codes by making links short (carrying 256 bits of key material plus a server-generated link ID) while preserving security against server MITM attacks. It explains why plain usernames or link shorteners are rejected (they make e2e security dependent on servers) and how the new design lets you see a contact's profile before connecting.

### blog/20250729-simplex-chat-v6-4-1-welcome-contacts-protect-groups-app-security.md
The v6.4.1 release fully delivers the new connection experience — short links (under 80 characters) that include profile and welcome message info so you see who you're connecting to before connecting, with an upgrade path for existing addresses/group links. It strengthens group protection with member review ("knocking"), a new moderator role to delegate moderation, and direct member feedback. Other additions include setting a default disappearing-message timer for new contacts, improved app integrity, and three new interface languages (Indonesian, Romanian, Vietnamese).

### blog/20260430-simplex-channels-v6-5-consortium-crowdfunding-freedom-of-speech.md
The v6.5 release (first beta) introduces SimpleX Channels, a public-publishing model where channel content is visible to chat relay operators (using multiple relays so no single one can block a channel) while the identities of owners and subscribers remain hidden — participation privacy enabled by SimpleX having no user identifiers. It announces the SimpleX Network Consortium, an agreement between a new SimpleX Network Foundation and the SimpleX Chat company to govern protocols and licensing perpetually and irrevocably, protecting network neutrality. It also launches community crowdfunding via private "Community Credits" to fund servers, development, and governance without surveillance or speculation.

## bots/

### bots/README.md
The primary guide to building SimpleX Chat bots. It covers why/what a bot is, configuring a bot profile (setting `peerType` to `"bot"`, command menus and the `/set bot commands` syntax, business addresses), and how to create one: run the CLI as a localhost WebSockets server, exchange JSON command/response messages keyed by `corrId`, and process chat events (with forward-compatibility rules for unknown types). It also documents security considerations (no auth, localhost-only, TLS proxy for remote bots), available SDKs (official TypeScript, unofficial Rust), and a list of useful community bots.

### bots/api/README.md
A short index page for the auto-generated bot API type reference, linking to the three sub-documents: COMMANDS.md (commands and responses), EVENTS.md (chat events), and TYPES.md (shared types).

### bots/api/COMMANDS.md
Auto-generated reference for bot API commands and their responses, organized into a table of contents by category (address, message, file, group, group-link commands, etc.) with anchor links to each command such as APISendMessages, APINewGroup, and APICreateGroupLink. Each entry documents the command string and the JSON response type.

### bots/api/EVENTS.md
Auto-generated reference for chat events the CLI sends to bots, grouped by category (contact connection, message, group events, and more) and split into "main" and "other" events. Examples include ContactConnected, NewChatItems, ReceivedGroupInvitation, and MemberRole, with anchor links to each event's detailed type.

### bots/api/TYPES.md
Auto-generated reference listing the shared JSON types used by bot API commands, responses, and events (e.g., AChatItem, CIContent, ChatError, AddressSettings), presented as an alphabetical anchor-linked index to each type definition.

## App bot & service READMEs

### apps/simplex-bot/README.md
Describes a minimal Haskell REPL chat-bot example. To build your own, you supply a welcome message and a `Contact -> String -> IO String` function mapping incoming messages to replies; the shipped example squares the number it receives. It lists ideas for extending it (calculator, translation, market quotes, AI dialogue, etc.).

### apps/simplex-bot-advanced/README.md
Describes a more advanced, event-based Haskell bot example for cases where the simple REPL bot is insufficient. The event-based approach lets the bot decide whether to connect based on factors like display name, disconnect abusive users, react to edits/deletions, handle replies with original context, process images and voice messages, and create groups connecting users.

### apps/simplex-broadcast-bot/README.md
Describes a broadcast bot that lets anyone connect and re-broadcasts messages from configured publisher users to all connected contacts, with configurable welcome and non-publisher reply messages. It is described as a "poor man's feed" used by the team to broadcast SimpleX server status notifications during maintenance or outages.

### apps/simplex-support-bot/README.md
A thorough operations README for a Node.js business-address support bot that triages incoming chats, optionally runs them through Grok (xAI), and routes handoffs to a team group. It documents prerequisites, SQLite (default) vs. PostgreSQL backend selection via `.npmrc`/`SIMPLEX_BACKEND` (including how to force a clean reinstall when switching), running via `npm start`, and a full flag and environment-variable reference. It closes with local-development-against-unreleased-lib instructions (`npm link`) and a troubleshooting section.

### apps/simplex-chat/README.md
A one-line stub for the SimpleX Chat CLI/terminal app that simply redirects readers to the installation and usage instructions in the repo's main README.

### apps/simplex-directory-service/README.md
A two-line note describing the Directory Service as a chat bot for registering and searching for groups, with superusers configured via CLI options.

## apps/multiplatform/ (Android + Desktop)

### apps/multiplatform/README.md
Contributor guide for the SimpleX Android and Desktop apps, a Kotlin Multiplatform (KMP) + Compose Multiplatform client. Covers Gradle build commands (Android APKs, desktop distributions, tests, native library cross-compilation), module/source-set structure, native Haskell core integration via JNI/CMake, `local.properties`/`gradle.properties` configuration, localization via Moko Resources, and Android/Desktop platform-specific notes. Also documents gotchas like the SHA certificate fingerprint needed for Android deep-link verification and the procedure for adding Material Symbol icons.

### apps/multiplatform/CODE.md
The authoritative coding/building instructions for working in the codebase, defining a mandatory three-layer documentation architecture (`product/` = what/why, `spec/` = how, source = execution) with bidirectional cross-references. It prescribes a strict navigation workflow (start at `product/concepts.md`, load product then spec then source context, consult `spec/impact.md`), a Change Protocol requiring every code change to update spec/ and product/ coherently, code-security/style rules, plan-storage conventions, and an adversarial self-review loop. It ends with a Document Map mapping every source file (commonMain, androidMain, desktopMain, Haskell core) to its spec and product docs.

### apps/multiplatform/common/src/commonMain/resources/assets/www/README.md
A two-line note about the WebView used for WebRTC calls. It warns not to edit `call.js` here directly, because it is compiled and copied from `call.ts` in `packages/simplex-chat-webrtc`.

### apps/multiplatform/product/README.md
The product overview for the Android + Desktop client, describing SimpleX Chat as the first messaging platform with no user identifiers, sharing a KMP+Compose codebase with a JNI-loaded Haskell core. It includes vision, target users, a 10-category Capability Map (Messaging, Contacts, Groups, Calling, Privacy/Security, User Management, Network, Customization, Data Management, Desktop Features) with per-feature Kotlin source links, Android (2-column) vs Desktop (3-column) navigation maps, the platform-abstraction mechanisms (expect/actual, runtime `PlatformInterface`, JNI FFI), Android background-messaging strategy, and links to all related product and spec docs.

### apps/multiplatform/product/concepts.md
The primary navigation entry point: a concept index mapping every product concept (PC1–PC31, e.g. Chat List, Direct/Group Chat, Calls, Notifications, Remote Desktop, Channels/Relays) to its product docs, spec docs, Kotlin source, and Haskell source. It also contains an Entity Index (User, Contact, GroupInfo, GroupMember, ChatItem, Connection, FileTransfer, etc.) with DB tables and create/read/mutate/delete operations, plus platform-specific (Android-only / Desktop-only) source indexes and cross-references.

### apps/multiplatform/product/glossary.md
A self-contained domain-term glossary for the Android/Desktop codebase, organized into nine sections: protocols/crypto (SMP, XFTP, double ratchet, PQ, SMP proxy), core data types (ChatItem, ChatInfo, CIContent, MsgContent, User, Contact, GroupInfo, etc.), the command/event protocol (CC, CR, API, ChatError, sendCmd/recvMsg), connection/identity, messaging features, calling/media (WebRTC, CallState, CallManager), notifications/background, application architecture (ChatController, ChatModel, AppPreferences, ModalManager), and configuration/preferences. Each term carries source-file references with line numbers where applicable.

### apps/multiplatform/product/rules.md
Specifies 18 business-rule invariants enforced by the clients, grouped into Security (RULE-01–05: mandatory E2E encryption, DB encryption at rest, local-auth gating, self-destruct profile, screen protection), Message Integrity (RULE-06–09: ordering verification, decryption-error surfacing, delivery-receipt consistency, TTL enforcement), Group Integrity (RULE-10–13: role-based access control, removal atomicity, link role default, member-blocking scope), File Transfer (RULE-14–15), Notification Delivery (RULE-16–17), and Call Integrity (RULE-18). Each rule states the invariant, its enforcement mechanism, and source locations.

### apps/multiplatform/product/gaps.md
Catalogs seven known gaps with severity, impact, and recommendations: UI error feedback (silent API failures), missing UI loading states, database passphrase not enforced (High), no forward-secrecy/PQ status indicator, the Haskell store layer being under-specified, Desktop voice recording not implemented (plus other `LALAL` placeholders like QR scanning and animated images), and the Desktop `Cryptor` being a non-functional placeholder that stores passphrases in plaintext (Critical). The Desktop Cryptor and recording gaps are flagged as the most serious.

### apps/multiplatform/product/flows/calling.md
Describes the end-to-end audio/video calling flow using WebRTC with signaling over SMP and an additional E2E shared-key layer. It details platform differences (Android `CallActivity` + WebView + foreground `CallService`; Desktop system browser pointed at a local NanoHTTPD/NanoWSD server on `localhost:50395`), prerequisites, and step-by-step outgoing-call initiation including the `Call` object and `CallState.WaitCapabilities` lifecycle.

### apps/multiplatform/product/flows/connection.md
Describes establishing a contact connection via the invitation-link model: one party creates a one-time invitation link or long-term SimpleX address and shares it out-of-band, the other connects via that link using SMP queues, with no central identity server. It walks through `apiAddContact`/`CC.APIAddContact` returning a `CR.Invitation` with a `CreatedConnLink` and `PendingContactConnection`, QR display, and notes incognito-mode support.

### apps/multiplatform/product/flows/file-transfer.md
Describes file transfer using inline SMP delivery for small files and XFTP for larger files (up to 1 GB), with optional AES encryption at rest via CryptoFile. It tabulates the size-threshold constants (MAX_IMAGE_SIZE, auto-receive thresholds for images/voice/video, MAX_FILE_SIZE_SMP ~7.6 MB, MAX_FILE_SIZE_XFTP 1 GB) defined in `Utils.kt`, explains how the core chooses the protocol, and covers CryptoFile encryption, auto-receive, manual download, and cancellation.

### apps/multiplatform/product/flows/group-lifecycle.md
Describes the lifecycle of decentralized groups (no central group server; the owner's device coordinates membership, messages delivered via pairwise SMP connections). It covers creating a group via `AddGroupView`/`apiNewGroup`/`CC.ApiNewGroup` returning `CR.GroupCreated` (creator becomes Owner), updating the group profile, and notes incognito support, roles, invitation links, member admission, blocking, and profile updates.

### apps/multiplatform/product/flows/messaging.md
Describes the core messaging flow: composing and sending text, images, video, voice, files, and link previews, plus reply/edit/delete/forward/react and special modes (timed, live, reports). It details how the compose area tracks context via `ComposeContextItem` variants, builds a `ComposedMessage`, and routes through `ChatController.apiSendMessages` → `CC.ApiSendMessages` → `CR.NewChatItems`, updating `ChatModel` and resetting `ComposeState`.

### apps/multiplatform/product/flows/onboarding.md
Describes the first-run flow that initializes the Haskell core, creates the local database, sets up the profile, configures server operators, and (on Android) selects the notification mode, tracked by the `OnboardingStage` enum in `AppPreferences.onboardingStage`. It contrasts the Android (`SimplexApp.onCreate`) and Desktop (`Main.kt main()`) initialization paths, both converging on the `chatMigrateInit` JNI call and shared `ChatController` logic, including Haskell runtime init, multiplatform setup, migrations, and migration-state handling.

### apps/multiplatform/product/views/call.md
Documents the audio/video call view for making/receiving E2E-encrypted WebRTC calls. It covers navigation (outgoing via `ChatInfoView`/`ChatView` buttons, incoming via `IncomingCallAlertView`, presented by `ActiveCallView` when `chatModel.showCallView == true`) and tabulates significant Android-vs-Desktop differences (WebView with `CallActivity`/PiP and `CallAudioDeviceManager` vs. NanoHTTPD browser-based WebRTC with `WebRTCController` and `NanoWSD` signaling).

### apps/multiplatform/product/views/chat-list.md
Documents the chat list / home screen (`ChatListView`), the navigation root showing all conversations sorted by last activity and providing access to profiles, settings, and new-chat creation. It covers navigation routing via `ChatListNavLinkView`, the `UserPicker`, platform layout differences (Android single-column with FAB; Desktop 3-column), and page sections such as the `ChatListToolbar`.

### apps/multiplatform/product/views/chat.md
Documents the full conversation view (`ChatView`) for direct, group, and note-to-self chats, supporting markdown text, media, voice, calls, reactions, replies, forwarding, reporting, and search. It describes navigation (entry from chat list, back-navigation clearing `chatModel.chatId` and stopping audio, sub-navigation to info/member/reports/support views) and page sections including the custom `ChatLayout` navigation bar.

### apps/multiplatform/product/views/contact-info.md
Documents the contact info view (`ChatInfoView`, presented via `ModalManager.end`) for viewing contact details, managing per-contact preferences, verifying security codes, managing connection settings (switch address, sync ratchet), and destructive actions like clear/delete. It covers sub-navigation to contact preferences, `VerifyCodeView`, and wallpaper editing, plus page sections including the contact info header.

### apps/multiplatform/product/views/group-info.md
Documents the group chat info view (`GroupChatInfoView`, presented via `ModalManager.end`) for viewing/managing group settings, member list, preferences, links, member admission, welcome messages, and moderation, with available actions gated by the user's role. It lists sub-navigation targets (group profile, add members, group link, preferences, welcome message, member info, wallpaper, member support) and page sections including the group info header.

### apps/multiplatform/product/views/new-chat.md
Documents the New Chat entry point for creating contacts/groups and connecting via one-time invitation links or scanned/pasted SimpleX links. It describes the `NewChatSheet` (presented from `ChatListView`) with three actions (create 1-time link, scan/paste link, create group), the `NewChatView` INVITE/CONNECT tabs with swipe switching on Android, and dismiss behavior prompting to keep or delete an unused invitation link.

### apps/multiplatform/product/views/onboarding.md
Documents the first-time setup UI (`OnboardingView`) covering app intro, profile creation, database passphrase setup (Desktop), server-operator conditions acceptance, SimpleX address creation, notification config (Android), and device-migration entry. It enumerates the `OnboardingStage` enum stages (Step1_SimpleXInfo, Step2_CreateProfile, LinkAMobile, Step2_5_SetupDatabasePassphrase, etc.) driving the linear flow until `OnboardingComplete`.

### apps/multiplatform/product/views/settings.md
Documents the Settings view (`SettingsView`, presented via `ModalManager.start`) for configuring notifications, network/servers, privacy, appearance, database management, call settings, and developer tools. It notes the entry point (UserPicker or chat-list toolbar) and tabulates Android-vs-Desktop differences (e.g. Desktop adds in-app `AppUpdater`; "Use from desktop" vs "Link a mobile") plus page sections.

### apps/multiplatform/product/views/user-profiles.md
Documents multi-profile management: the `UserPicker` overlay for quick switching from the chat list and `UserProfilesView` for full management (create, switch, hide with password, mute, delete profiles). It describes navigation entry points, sub-navigation to create/edit profile, user address, and chat preferences, and page sections including the `UserPicker` panel.

### apps/multiplatform/spec/README.md
The technical specification index/overview. It summarizes the app as a KMP application targeting Android and Desktop with a Compose UI talking to a Haskell crypto core over a JNI bridge (`libapp-lib`), describes the three Gradle modules (`:common`, `:android`, `:desktop`) with all real logic in `commonMain`, and provides a dependency graph plus links to all spec documents, product documents, and source entry points.

### apps/multiplatform/spec/api.md
The Chat API reference for the JNI command/response bridge between Kotlin/Compose and the Haskell core, following a command/response JSON protocol. It is organized by command categories (user management, chat lifecycle, message/group/contact/file/call operations, settings & network, chat tags, server operators, archive) and additionally documents response types, event types, error types, and source files.

### apps/multiplatform/spec/architecture.md
Specifies the overall system architecture as a three-layer system (Compose UI → application logic [ChatModel, ChatController, AppPreferences, NtfManager, ThemeManager] → Haskell core). It covers module structure, the JNI bridge, app lifecycle, event streaming, and platform abstraction (expect/actual + runtime `PlatformInterface`), with source-file references.

### apps/multiplatform/spec/database.md
Specifies database and storage handling: two SQLite databases (chat `_chat.db` and agent `_agent.db`) managed entirely by the Haskell core, with Kotlin never accessing them directly (only via the JNI protocol). It documents file paths, the Haskell store modules, migrations (via `chatMigrateInit` and `DBMigrationResult`), database encryption, file storage, and export/import.

### apps/multiplatform/spec/impact.md
The impact graph mapping source files to the product concepts (PC1–PC31) they affect, used to determine which product docs must be updated when a source file changes. It covers Kotlin Multiplatform sources (commonMain, androidMain, desktopMain), the Android and Desktop app modules, and the shared Haskell core, and begins with a legend defining each product-concept ID.

### apps/multiplatform/spec/state.md
Specifies the state-management model: a singleton, Compose-reactive architecture centered on the `@Stable` `ChatModel` object, whose mutable fields are Compose `MutableState`/`MutableStateFlow`/snapshot collections that drive recomposition, with no ViewModel, DI, or Redux/MVI layer. It details `ChatModel`, `ChatsContext`, `Chat`, and `AppPreferences` (150+ preferences via multiplatform-settings), and the flow from `ChatController` command dispatch and event processing into model mutations.

### apps/multiplatform/spec/client/chat-list.md
Specification for the chat list (Source: `ChatListView.kt`). It documents the `ChatListView` composable, data sources, the filter system, chat preview rendering, `ChatListNavLinkView` click routing, the tag system, and the `UserPicker`, with an executive summary and source-file references.

### apps/multiplatform/spec/client/chat-view.md
Specification for the conversation view (Source: `ChatView.kt`). It documents the `ChatView` composable, the message list, `ChatItemView`, message types, context-menu actions, and the `ChatInfoView` and `GroupChatInfoView` detail views, with source-file references.

### apps/multiplatform/spec/client/compose.md
Specification for message composition (Source: `ComposeView.kt`, `SendMsgView.kt`). It documents the serializable `ComposeState` data class, the `ComposePreview` and `ComposeContextItem` sealed classes, the `SendMsgView` text field/action buttons, attachment handling, and draft persistence (gated by a privacy preference), supporting link previews, media/voice attachments, reply/edit/forward contexts, live messages, mentions, reports, and timed messages.

### apps/multiplatform/spec/client/navigation.md
Specification for app navigation (Source: `App.kt`, ~470 lines). It documents the `AppScreen` and `MainScreen` composables, the Android (2-column) and Desktop (3-column) layouts, the `ModalManager` (start/center/end/fullscreen placements), the authentication gate, and the onboarding flow.

### apps/multiplatform/spec/services/calls.md
Specification for the WebRTC calling service: signaling over SMP with platform-specific media implementations (Android WebView + `CallActivity` + foreground `CallService`; Desktop system browser + NanoWSD WebSocket server on localhost), sharing a common `CallManager` and `CallState` enum, with JSON-serialized call commands/responses exchanged with the WebRTC JavaScript layer. It covers the call state machine, both platform implementations, the common call API, and `IncomingCallAlertView`.

### apps/multiplatform/spec/services/files.md
Specification for the file-transfer service: inline SMP transfers for small files and XFTP for larger files (up to 1 GB), with optional at-rest encryption via `CryptoFile` backed by the core's native crypto. It documents file size constants, CryptoFile, platform-specific storage paths (Android `dataDir`; Desktop XDG/AppData/Application Support), API commands, and auto-receive logic for images/voice/videos below configurable thresholds.

### apps/multiplatform/spec/services/notifications.md
Specification for the notification system: a common `NtfManager` abstract class plus platform-specific strategies. Android uses channels, grouped summaries, full-screen call intents, and either a foreground `SimplexService` or periodic `WorkManager` background fetching; Desktop uses the TwoSlices library with OS-native fallbacks. It also covers notification privacy via `NotificationPreviewMode` (MESSAGE/CONTACT/HIDDEN) and source files.

### apps/multiplatform/spec/services/theme.md
Specification for the theme engine, implementing a four-level cascade (per-chat → per-user → global → built-in preset) with four presets (LIGHT, DARK, SIMPLEX, BLACK) each defining Material `Colors` and custom `AppColors`. It covers `ThemeManager`, theme types, the color system, the `SimpleXTheme` composable (wrapping `MaterialTheme` with CompositionLocal providers for app colors and wallpaper), platform theming, wallpaper customization, and YAML import/export.

## apps/ios/

### apps/ios/README.md
Developer-oriented overview of the iOS app: a SwiftUI application that interfaces with the Haskell core via C FFI and shares the SimpleXChat framework across the main app, a Notification Service Extension (NSE), and a Share Extension (SE). Documents the five Xcode targets, build/test commands (deployment target iOS 15.0+, Swift 5.0), the FFI bridge (`SimpleX.h`/`API.swift`), per-target Haskell RTS heap sizes (64MB app, 512KB NSE, 1MB SE), state management (ChatModel, ItemsModel, AppTheme), App Group data sharing and Keychain usage, localization (31 languages), the optional `SIMPLEX_ASSETS` flag, and background capabilities (audio/fetch/remote-notification/voip, `simplex://` deep linking, BGTaskScheduler).

### apps/ios/CODE.md
The authoritative coding-and-building guide enforcing a three-layer documentation architecture (`product/` = what/why, `spec/` = how, Swift/Haskell source = execution) with mandatory navigation, change, and adversarial self-review protocols. Mandates loading product and spec context before writing code, updating all three layers on every change, keeping `#Lxx-Lyy` line references current, and adding `[GAP]`/`[REC]` annotations. Includes code-security/style rules and a full Document Map mapping iOS Swift sources and Haskell core sources to their spec and product docs.

### apps/ios/LOCALIZATION.md
Short workflow guide for localization in the iOS app. Explains the three ways Xcode generates localization keys (standard SwiftUI components, `LocalizedStringKey` parameters, and `NSLocalizedString`), the export/import XLIFF workflow via Xcode's Product menu using the `SimpleX Localizations` folder, and the development tip to enable "Show non-localized strings" so untranslated text appears in all caps.

### apps/ios/SimpleXChat/SimpleXChat.docc/SimpleXChat.md
An empty/placeholder DocC documentation catalog file for the `SimpleXChat` framework. It contains only unfilled Xcode template tokens (`@START_MENU_TOKEN@`) for Summary, Overview, and Topics, with no real content.

### apps/ios/product/README.md
Top-level product overview for the iOS app. States the vision (no user identifiers, double-ratchet + optional post-quantum E2E encryption, decentralized user-controlled SMP relays), target users, and a detailed Capability Map across 10 areas (Messaging, Contacts, Groups, Calling, Privacy & Security, User Management, Network, Customization, Data Management, Desktop Integration) each mapped to key Swift source files. Closes with an ASCII Navigation Map of the view hierarchy and links to related specs.

### apps/ios/product/concepts.md
The primary navigation entry point: a concept index mapping every product concept to its product docs, spec docs, Swift source files, and Haskell core source files via bidirectional links. Section 1 is a Feature Concepts table (Chat List, Direct/Group Chat, message composition/reactions/editing/deletion, timed/voice messages, file transfer, connection, verification, group management/links/roles, calls, notifications, user profiles, and more); a second section provides an Entity Index. Swift paths are relative to `apps/ios/` and Haskell paths use the `../../src/` prefix.

### apps/ios/product/gaps.md
Aggregation of `[GAP]` (known issues) and `[REC]` (recommendations) annotations discovered during specification analysis, organized by product area. Examples include no user-visible error on FFI command failure, no loading indicator during initial chat-list population, and the bulk member-role change API supporting batch while the iOS UI only calls it one member at a time. Each entry cites its source spec doc and a recommended fix.

### apps/ios/product/glossary.md
Domain term glossary for the iOS app, organized into nine categories (Protocols & Cryptography, Core Data Types, Commands & Events, Connection & Identity, Messaging Features, Calling & Media, Notifications & Background, Application Architecture, Configuration & Preferences). Defines terms such as SMP, SMP Server, and XFTP with *See:* references pointing down to spec docs, Swift source, and the simplexmq protocol specs/implementation.

### apps/ios/product/rules.md
Catalog of business invariants enforced by the iOS app and Haskell core, each stating the rule, where it is enforced, and a link to the relevant spec. The opening Security & Privacy rules cover no user identifiers (RULE-01), mandatory E2E encryption (RULE-02), SQLCipher database encryption at rest (RULE-03), and local authentication before content access (RULE-04), citing simplexmq and specific Swift/Haskell enforcement points.

### apps/ios/product/flows/calling.md
User flow for WebRTC audio/video calling. Calls are 1:1 only, end-to-end encrypted with an additional shared key negotiated over the E2E-encrypted SMP channel, and use CallKit for native call UI with a fallback mode for regions where CallKit is restricted (China). Signaling (offer/answer/ICE candidates) is exchanged via SMP messages rather than a central signaling server; documents prerequisites and the step-by-step initiate-call process through `CallController`.

### apps/ios/product/flows/connection.md
User flow for establishing contact between two users without any user identifiers, via one-time invitation links or permanent SimpleX addresses, each creating unique unidirectional SMP queues so no server can correlate sender and receiver. Covers incognito mode and walks through creating an invitation link (`apiAddContact(incognito:)` from `NewChatView`) and subsequent connection steps.

### apps/ios/product/flows/file-transfer.md
User flow for file and media sharing: small files sent inline within SMP messages and large files (up to 1GB) via the chunked, encrypted XFTP protocol, all E2E encrypted with optional local at-rest encryption via `CryptoFile`. Includes a size-limits table with exact byte constants (e.g., inline image 255KB, max XFTP file 1GB, max SMP file ~8MB) and auto-receive thresholds for images/voice/video.

### apps/ios/product/flows/group-lifecycle.md
End-to-end group management flow: creating groups, inviting members, joining via links, managing roles and admission, and deletion. Notes that groups use the same E2E encryption as direct messages (each member pair has independent encrypted channels) and group metadata is distributed via the group protocol. Walks through group creation from `AddGroupView` via `apiNewGroup(incognito:groupProfile:)`.

### apps/ios/product/flows/messaging.md
Complete message lifecycle flow: composing, sending, receiving, editing, deleting, reacting, replying, and forwarding, all E2E encrypted via SMP. Describes the division of labor (Haskell core handles encryption/routing/persistence; Swift UI drives composition and display) and walks through sending a text message from `ComposeView`/`SendMessageView`, including async link-preview fetching and building a `ComposedMessage`.

### apps/ios/product/flows/onboarding.md
First-time setup and migration flow: app initialization, profile creation, server-operator selection, notification configuration, and database import/export for device migration. Notes the Haskell runtime core and SQLite databases shared between the main app and NSE, and documents the ordered launch sequence in `SimpleXApp.init()` (haskell_init, default preferences registration, group defaults setup, etc.).

### apps/ios/product/views/call.md
Product page for the audio/video call screen. Describes making/receiving E2E encrypted WebRTC calls with CallKit integration, picture-in-picture for video, audio-device selection, and a collapsible call overlay. Documents entry points (outgoing buttons in `ChatInfoView`/`ChatView`; incoming `IncomingCallView` banner or native CallKit), presentation via `ActiveCallView` when `chatModel.activeCall` is set, and collapse/dismiss behavior.

### apps/ios/product/views/chat-list.md
Product page for the home screen (chat list). Describes it as the navigation root showing all conversations sorted by last activity, with access to profiles, settings, and new-chat creation. Documents that it is presented by `ContentView` when `chatModel.chatId == nil`, uses `NavStackCompat`, and exposes a UserPicker sheet (avatar tap) linking to sub-sheets for address, preferences, profiles, current profile, use-from-desktop, and settings.

### apps/ios/product/views/chat.md
Product page for the conversation view (direct chat, group chat, or note-to-self). Supports markdown text, media/voice attachments, E2E encrypted calls, reactions, replies, forwarding, and search/filtering. Documents entry via tapping a chat row, presentation through `NavStackCompat` bound to `chatModel.chatId`, back navigation (setting `chatId = nil`), and sub-navigation to `ChatInfoView`/`GroupChatInfoView`/`GroupMemberInfoView`.

### apps/ios/product/views/contact-info.md
Product page for the contact info screen: viewing contact details, managing per-contact preferences, verifying security codes for E2E encryption, managing connection settings, and destructive actions (block/delete). Documents entry via the info button in `ChatView` for a direct chat, presentation as a `NavigationView` sheet via `showChatInfoSheet`, and sub-navigation to `ContactPreferencesView`, `VerifyCodeView`, and the wallpaper editor.

### apps/ios/product/views/group-info.md
Product page for the group chat info screen: viewing/managing group settings, member list, preferences, group links, member admission, welcome messages, and moderation, with available actions gated by the user's role (member/moderator/admin/owner). Documents entry via the info button in `ChatView` for a group, presentation as a `NavigationView` sheet, and sub-navigation to profile editing, add-members, group link, preferences, and welcome-message views.

### apps/ios/product/views/new-chat.md
Product page for the new chat / connection screen, the primary onramp for new E2E encrypted connections via one-time invitation links or scanning/pasting SimpleX links. Documents entry via the new-chat (pencil) toolbar button, the `NewChatMenuButton` dropdown ("New chat"/"Create group"), the segmented invite/connect tabs (with swipe-to-switch), and the keep-or-delete-invitation prompt on dismiss.

### apps/ios/product/views/onboarding.md
Product page for the first-time setup flow guiding users through app introduction, profile creation, server-operator conditions acceptance, and notification configuration, plus a device-migration entry point. Documents that `OnboardingView` renders steps based on the `OnboardingStage` enum, progression is linear with back navigation hidden on later steps, and completion sets `onboardingStageDefault` to `.onboardingComplete`. Begins enumerating steps starting with the Welcome/SimpleX Info screen.

### apps/ios/product/views/settings.md
Product page for the settings screen covering notifications, network/servers, privacy, appearance, database management, call settings, and developer tools. Documents entry via the UserPicker (avatar tap) Settings option, presentation through `UserPickerSheetView(sheet: .settings)` wrapping `SettingsView` in a `NavigationView` titled "Your settings", with each row a `NavigationLink` to a dedicated view.

### apps/ios/product/views/user-profiles.md
Product page for managing multiple chat profiles within a single app instance: creating, switching, hiding, muting, and deleting profiles, with hidden profiles password-protected and supporting a self-destruct password. Documents entry via UserPicker -> "Your chat profiles", presentation through `UserPickerSheetView(sheet: .chatProfiles)` wrapping `UserProfilesView`, and sub-navigation to create/edit profile and user-address views.

### apps/ios/spec/README.md
Specification suite overview describing the iOS app as a native SwiftUI frontend communicating with the Haskell core (`chat_ctrl`) over C FFI, where all chat logic, encryption, protocol, and DB operations live in Haskell while iOS handles UI, system integration (CallKit, push, background tasks), preferences, and theming, with the DB shared with the NSE. Includes an ASCII dependency graph (SimpleXApp -> ChatModel/SimpleXAPI/Haskell core, Views, Models, Services, Extensions) and serves as the index for the other spec documents.

### apps/ios/spec/api.md
Complete reference for the API contract between the Swift UI and the Haskell core: the `ChatCommand`, `ChatResponse`, `ChatEvent`, and `ChatError` types. Sourced from `AppAPITypes.swift`, `SimpleXAPI.swift`, `APITypes.swift`, and `API.swift`, it documents command categories, response/event/error types, the FFI bridge functions, and the `APIResult` result type.

### apps/ios/spec/architecture.md
System architecture spec for the iOS app covering the layered architecture, the FFI bridge, the event-streaming system, database architecture, app lifecycle, the extension model (NSE/SE), and remote desktop control. Sourced from `SimpleXApp.swift`, `AppDelegate.swift`, `ContentView.swift`, `ChatModel.swift`, `SimpleXAPI.swift`, and the API type files with explicit line ranges.

### apps/ios/spec/database.md
Database and storage spec covering the database overview, file paths, the Haskell store modules, migrations, database encryption (SQLCipher), file storage, and export/import functionality. Sourced primarily from `FileUtils.swift`, it links up to the architecture and state specs and down to the relevant Haskell store modules.

### apps/ios/spec/impact.md
The impact graph mapping each source file to the product concepts it affects, used to determine which product documents must be updated when a source file changes. Derived from the CODE.md Document Map and `product/concepts.md`, it begins with a Product Concept Legend assigning IDs (PC1 = Chat List, PC2 = Direct Chat, etc.) used throughout the mapping tables.

### apps/ios/spec/state.md
State-management spec for the app's observable state architecture, sourced from `ChatModel.swift` and `ChatTypes.swift`. Documents the primary `ChatModel` app state, `ItemsModel` per-chat message state, `ChatTagsModel` tag filtering, `ChannelRelaysModel`, the per-conversation `Chat` state, and `ChatInfo` conversation metadata, with line-anchored source references.

### apps/ios/spec/client/chat-list.md
Client-module spec for the conversation list: covers `ChatListView`, `ChatPreviewView`, filtering, search, swipe actions, and the user picker. Sourced from `ChatListView.swift`, it links to the chat-view, navigation, and state specs and up to the chat-list product view.

### apps/ios/spec/client/chat-view.md
Client-module spec for message rendering and the conversation view: covers `ChatView`, `ChatItemView` message routing, the various chat item types, and context-menu actions. Sourced from `ChatView.swift`, `ChatInfoView.swift`, `GroupChatInfoView.swift`, `ChannelMembersView.swift`, and `ChannelRelaysView.swift`, linking to the compose, state, and api specs.

### apps/ios/spec/client/compose.md
Client-module spec for message composition: covers the compose bar (`ComposeView`), attachment types, reply/edit/forward modes, voice recording, mentions, and the `ComposeState` machine. Sourced from `ComposeView.swift`, it links to the chat-view, file-transfer, and api specs and to the chat product view.

### apps/ios/spec/client/navigation.md
Client-module spec for navigation architecture: the navigation stack, deep linking, sheet presentation, and the call overlay. Sourced from `ContentView.swift`, `NewChatView.swift`, `SettingsView.swift`, `OnboardingView.swift`, and `UserProfilesView.swift`, it documents the root `ContentView` and the navigation stack structure.

### apps/ios/spec/services/calls.md
Service spec for the WebRTC calling system: `CallController`, `WebRTCClient`, CallKit integration, and SMP-based signaling. Sourced from `CallController.swift`, `WebRTCClient.swift`, `ActiveCallView.swift`, and `CallTypes.swift`, linking to the architecture, api, and notifications specs.

### apps/ios/spec/services/files.md
Service spec for file transfer: the inline and XFTP transfer methods, auto-receive thresholds, `CryptoFile` encryption, and file size constants. Sourced from `FileUtils.swift`, `CryptoFile.swift`, `ChatTypes.swift`, `AppAPITypes.swift`, and `SimpleXAPI.swift`, linking to the compose, chat-view, api, and database specs.

### apps/ios/spec/services/notifications.md
Service spec for the push notification system: `NtfManager`, the Notification Service Extension (NSE), notification modes, and the token lifecycle. Sourced from `NtfManager.swift`, `BGManager.swift`, `Notifications.swift`, and the NSE's `NotificationService.swift`, linking to the architecture, api, and navigation specs.

### apps/ios/spec/services/theme.md
Service spec for the theming engine: `ThemeManager`, the default themes, customization layers, wallpapers, and YAML export. Sourced from `ThemeManager.swift`, `AppearanceSettings.swift`, `ThemeTypes.swift`, `ChatWallpaperTypes.swift`, and `Theme.swift`, linking to the state and architecture specs.

## packages/

### packages/simplex-chat-client/typescript/README.md
README for the `@simplex-chat/webrtc-client` TypeScript WebSocket client, now marked DEPRECATED in favor of the Node.js library. It defines a WebSocket API client for the SimpleX Chat CLI run as a server (profiles, invitations, addresses, groups, files), lists use cases (chat bots, equipment control), and provides a quick-start with a squaring-bot example. It relies on the `@simplex-chat/types` package and is licensed AGPLv3.

### packages/simplex-chat-client/types/typescript/README.md
A short README for the `@simplex-chat/types` package, which provides auto-generated TypeScript types for the bots API (commands, responses, events, and the types they use). It is consumed by the `simplex-chat` Node.js library and is licensed AGPLv3.

### packages/simplex-chat-nodejs/README.md
README for the official `simplex-chat` Node.js library that replaces the deprecated WebRTC client. It gives a quick-start squaring-bot using the high-level `bot.run()` API, covers SQLite (default) and PostgreSQL backend selection plus the `DbConfig` discriminated union, and documents the four modules (`bot`, `api`, `core`, `util`) and supported chat functions. Licensed AGPLv3 and built on `@simplex-chat/types`. (Note: the auto-generated TypeDoc API reference under `packages/simplex-chat-nodejs/docs/` is excluded from this inventory.)

### packages/simplex-chat-python/README.md
README for the Python 3.11+ SimpleX Chat bot client, presented as the equivalent of the Node.js library. It shows install (`pip install simplex-chat`, with lazy native-lib download), a decorator-based quick-start bot (`@bot.on_message`, `@bot.on_command`, `@bot.on_event` with first-match-wins ordering), and development/release workflows including how to regenerate the generated wire types. Licensed AGPL-3.0.

### packages/simplex-chat-webrtc/README.md
A three-line README for the WebView component used for WebRTC calls in SimpleX Chat, giving only the `npm i` and `npm run build` commands.

## website/

### website/README.md
The website's README, consisting solely of license information. The site code is AGPLv3, but the SimpleX name, logo, branding, and graphic assets are excluded and governed by the TRADEMARK and ASSETS_LICENSE files; permission is required to reuse graphics, while texts may be quoted with attribution.

### website/plans/2026-02-25-why-page.md
An implementation plan for adding a `/why` philosophy/manifesto page to the website. It specifies the ~200-word, 7-paragraph translatable content, the typographic treatment per paragraph, and a file-by-file modification table (new `src/why.html`, plus edits to `langs/en.json`, `.eleventy.js`, `web.sh`, language data, navbar, and main layout), with the language dropdown showing only fully translated locales.

### website/plans/2026-05-20-links-page.md
An implementation plan for a `/links` page showing 300+ external publications, reviews, bots, and community content about SimpleX, all rendered in the DOM for SEO with client-side pagination. It details a Node.js markdown parser module (imported by `.eleventy.js`, like the glossary parser) that reads `docs/LINKS.md` into structured entries, plus image handling and the line-by-line metadata parsing rules.

### website/src/token.md
The "SimpleX Community Credits" website page explaining a crowdfunding strategy to fund network infrastructure. It argues that ad-funded or single-investor models compromise privacy/control, and proposes Community Credits as non-tradable prepaid infrastructure credits, paired with a community crowdfunding effort. It includes a Reg CF "testing the waters" legal disclaimer and links to register interest.

### website/src/_includes/sections/messaging.md
A marketing content include titled "The World's Most Secure Messaging" used in a website section. It lists key selling points (ultimate security with post-quantum E2E encryption, unique privacy with no user IDs, no spam, data ownership, secure decentralization with 4 servers per chat) and short instructions for connecting to others via a 1-time link.

### website/src/.well-known/README.md
Explains the `.well-known` files that enable opening SimpleX links directly in the app. For Android it documents the `assetlinks.json` certificate hashes for the Play Store, GitHub APK, and F-Droid builds; for iOS it explains the workaround for serving `apple-app-site-association` with the correct JSON content type on GitHub Pages (using a directory with an `index.json`).

### website/src/fonts/GT-Walsheim/README.md
A single-line notice stating that the GT-Walsheim fonts are not free/open-source and cannot be reused in other projects.

## scripts/

### scripts/db/README.md
A detailed runbook for migrating SimpleX Chat data between SQLite and PostgreSQL backends. The SQLite→Postgres direction covers decrypting SQLCipher databases, creating the Postgres user/db/schemas via a CLI built with `-fclient_postgres`, loading data with pgloader, fixing identity sequences, row-count verification, and building the desktop app with the Postgres backend; it also documents the reverse Postgres→SQLite path using `pg2sqlite.py` plus BLOB fix-ups.

### scripts/nix/README.md
A short three-step guide for updating the Nix package config: install `nix`/`gawk`/`jq`, enter a `nix-shell` with `nix-prefetch-git`, and regenerate `sha256map.nix` by running the `update-sha256.awk` script against `cabal.project`.

## Misc

### src/Simplex/Chat/protocol.md
A design document for the chat message protocol layered over the SMP agent. It records design constraints (fixed transport block sizes, multi-part messages, chunked large-binary transfer), open questions about content-type vocabularies (MIME vs. SimpleX namespaces), and an ABNF grammar for the message body inside an agent MSG (chat message IDs, namespaced message events, parameters, and content/body parts).

### media-logos/README.md
A brief note inviting use of the provided SimpleX logos in publications about SimpleX Chat, and pointing to blog-post screenshots and diagrams that may also be used with attribution.

### assets/ASSETS_LICENSE.md
The license terms for the repository's graphic assets (illustrations, images, icons, visual designs), declaring them proprietary and explicitly not covered by the AGPLv3 that applies to source code. It permits only unmodified use within the unmodified SimpleX Chat app and screenshots in publications with prior written permission, prohibiting all other modification/redistribution, and gives chat@simplex.chat as the contact for permission requests.
