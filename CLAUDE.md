# MacKanban (mac-kanban)

## Project

- Vocabulary: `GLOSSARY.md`. Decisions: `docs/adr/`. Spec: `docs/specs/0001-mvp.md`. Tickets: `.scratch/mackanban-mvp/issues/` (MVP and its follow-ups) and one folder per later spec, e.g. `.scratch/show-board-hotkey/issues/` (spec 0002); each has an index with statuses in its `README.md` (keep it in sync when a ticket's status changes). Backlog (Inbox / MVP / Later / Not planned): `BACKLOG.md`; "add to backlog: …" goes to its Inbox.
- Built with SwiftPM (no Xcode installed): `swift build`; tests via `scripts/test.sh` (works around Swift Testing with Command Line Tools only); `scripts/bundle.sh` produces an ad-hoc-signed `build/MacKanban.app`. `scripts/install.sh` copies it to `~/Applications/` and restarts MacKanban. App icon: `swift scripts/icon-artwork.swift Resources/AppIcon.png` draws the artwork, `scripts/make-icon.sh` turns it into `Resources/AppIcon.icns` (both committed; `bundle.sh` only copies the `.icns`).
- Screenshots and trying things by hand without touching the real Board: `swift run SampleBoard [--replace] [--blocked] <file.sqlite>` writes a Board with Cards of every age (it ends in Triage; `--blocked` fills it until creating is blocked) and prints its absolute path; quit MacKanban (`pkill -x MacKanban`), then `open -n --env MACKANBAN_STORE=<absolute path> ~/Applications/MacKanban.app`. A sample store has its own settings, so its WIP Limit doesn't touch the real one. Driving the UI (clicks, keystrokes) isn't possible: the terminal has no Accessibility permission.
- In Claude Code, build/test commands need the sandbox disabled: the sandbox blocks the Swift macro plugin server.
- No SwiftUI macros (`@State`, `@Observable`): their plugins ship only with Xcode. SwiftUI views may use `@AppStorage`; anything with its own state is AppKit.
- The Core Data model is defined in code (`StoreModel`), so schema changes can't migrate automatically (ADR 0002). Don't change it without planning the migration.
- The Capacity and Urgency rules are deliberately fixed and strict (ADR 0001). Don't add settings, floors or resets to them without a new ADR.
