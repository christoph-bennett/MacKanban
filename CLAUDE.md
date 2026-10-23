# MacKanban (mac-kanban)

## Project

- Vocabulary: `GLOSSARY.md`. Decisions: `docs/adr/`. Spec: `docs/specs/0001-mvp.md`. Tickets: `.scratch/mackanban-mvp/issues/` (index with statuses in its `README.md`; keep it in sync when a ticket's status changes). Backlog (Inbox / MVP / Later / Not planned): `BACKLOG.md`; "add to backlog: …" goes to its Inbox.
- Built with SwiftPM (no Xcode installed): `swift build`; tests via `scripts/test.sh` (works around Swift Testing with Command Line Tools only); `scripts/bundle.sh` produces an ad-hoc-signed `build/MacKanban.app`. `scripts/install.sh` copies it to `~/Applications/` and restarts MacKanban.
- In Claude Code, build/test commands need the sandbox disabled: the sandbox blocks the Swift macro plugin server.
- No SwiftUI macros (`@State`, `@Observable`): their plugins ship only with Xcode. SwiftUI views may use `@AppStorage`; anything with its own state is AppKit.
- The Core Data model is defined in code (`StoreModel`), so schema changes can't migrate automatically (ADR 0002). Don't change it without planning the migration.
- The Capacity and Urgency rules are deliberately fixed and strict (ADR 0001). Don't add settings, floors or resets to them without a new ADR.
