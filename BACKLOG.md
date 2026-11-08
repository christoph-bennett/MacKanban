# Backlog

Ideas and requirements not yet built. New items go to **Inbox**. Once triaged they move to **MVP** (and become a ticket in `.scratch/mackanban-mvp/issues/`), **Later**, or **Not planned** (with the reason). Vocabulary: [GLOSSARY.md](./GLOSSARY.md). MVP scope: [spec 0001](./docs/specs/0001-mvp.md).

## Inbox

- **Restore a Card from the Archive** back to the Board, e.g. a Card Discarded by mistake (2026-11-06). Open: where it goes (Backlog?), whether a restored Discarded Card is an Open Card again and costs Capacity, whether a restored Done Card loses its Throughput. Left out of spec 0003 (Archive), 2026-11-06.

## MVP

Everything in [spec 0001](./docs/specs/0001-mvp.md), including **Sample Cards** (user stories 49–53, ADR 0005, ticket 12; grilled 2026-10-26).

- **Global New Card hotkey** from any app, going through Triage and the Capacity block like the sheet. Deferred 2026-10-23. A global hotkey that shows the Board came first (2026-11-05, [spec 0002](./docs/specs/0002-show-board-hotkey.md)); it brings in KeyboardShortcuts (ADR 0006), which this item would reuse. Asked for again 2026-11-07 as a second recorder in Settings > Shortcuts, beside Show Board, and moved from Later to MVP. Decided the same day: it brings the Board forward with the New Card sheet, no panel of its own. Ticket 17, done 2026-11-07.
- **Info icon beside "Counts" in the Archive** (requested 2026-11-07): a small ⓘ next to the column title; hovering it shows a short explanation in plain words, not technical. Draft (wording changed 2026-11-07: "Done or Archived", not "finished"): "Done or Archived Cards each give you room for one more Card, for 14 days after they moved to Done. The bar shows how much of that time is left. After that, the Card stays here but no longer gives you room." Follow-up to spec 0003, ticket 05. Ticketed 2026-11-08 as archive ticket 07 (`.scratch/archive/issues/`); the ⓘ is required, not just a hover text on the title. Done 2026-11-08.
- **Hide the Dock icon** (requested 2026-11-07): an option in Settings > General, on by default; without the Dock icon MacKanban runs from the menu bar extra and its hotkeys. Grilled the same day: Settings gets a Board tab for the WIP Limit and Archive Delay first, and the menu bar extra gets Open Archive. [Spec 0004](./docs/specs/0004-settings-board-tab-and-dock-icon.md), tickets in `.scratch/settings-and-dock/issues/`. Done 2026-11-08.

## Later

- **Manual reordering ("planning order")** in Backlog and Doing, so I can plan which Cards to do first. The order is only a plan: it never affects Urgency or Capacity, and the default stays oldest first. Deferred 2026-10-23: fixed order first, see how it feels.
- **Dashboard** of the Board's history: Throughput over time, how long Cards spend in each Column, Cards kept repeatedly in Triage, Creation Blocked frequency, WIP Limit changes. The MVP already records every Card Event and Board Event for it (ADR 0002). Requested 2026-10-23.
- **iCloud sync** via `NSPersistentCloudKitContainer`. The model is already CloudKit-ready (ADR 0002). Needs a Developer ID signature, an iCloud container and entitlements, plus a rule for merging conflicting Column Visits.

## Not planned

- **Notifications** (a Card turned red, Capacity dropped). The pressure applies when you come to add something, and nagging from outside the app is a different product. Decided 2026-10-23.
- **Configurable Urgency thresholds or Capacity formula.** Setting them loose would switch off the mechanism (ADR 0001).
- **Custom Columns, multiple Boards, due dates, priorities, tags.** One fixed Board is the point, and due dates or priorities would compete with age as the urgency signal.
