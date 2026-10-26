# Backlog

Ideas and requirements not yet built. New items go to **Inbox**. Once triaged they move to **MVP** (and become a ticket in `.scratch/mackanban-mvp/issues/`), **Later**, or **Not planned** (with the reason). Vocabulary: [GLOSSARY.md](./GLOSSARY.md). MVP scope: [spec 0001](./docs/specs/0001-mvp.md).

## Inbox

- **Sample data on first launch.** On first launch, offer to fill the Board with sample Cards (everyday chores, nothing techy); the offer may also stay in the menu bar extra's menu. Sample Cards can be removed later without touching Cards the user created, even ones added on top. To grill (`/grill-with-docs`) before ticketing. Open questions: how sample Cards are told apart without a schema change (ADR 0002), whether they age, cost Capacity and show up in Throughput and the event log like real Cards, what happens to a sample Card the user edited or moved, and whether removing them is a Discard or leaves no trace. Raised 2026-10-26.

## MVP

Everything in [spec 0001](./docs/specs/0001-mvp.md).

## Later

- **Manual reordering ("planning order")** in Backlog and Doing, so I can plan which Cards to do first. The order is only a plan: it never affects Urgency or Capacity, and the default stays oldest first. Deferred 2026-10-23: fixed order first, see how it feels.
- **Global New Card hotkey** with a small quick-add panel from any app, going through Triage and the Capacity block like the sheet. Would bring in KeyboardShortcuts as in MacJot. Deferred 2026-10-23.
- **Dashboard** of the Board's history: Throughput over time, how long Cards spend in each Column, Cards kept repeatedly in Triage, Creation Blocked frequency, WIP Limit changes. The MVP already records every Card Event and Board Event for it (ADR 0002). Requested 2026-10-23.
- **iCloud sync** via `NSPersistentCloudKitContainer`. The model is already CloudKit-ready (ADR 0002). Needs a Developer ID signature, an iCloud container and entitlements, plus a rule for merging conflicting Column Visits.

## Not planned

- **Notifications** (a Card turned red, Capacity dropped). The pressure applies when you come to add something, and nagging from outside the app is a different product. Decided 2026-10-23.
- **Configurable Urgency thresholds or Capacity formula.** Setting them loose would switch off the mechanism (ADR 0001).
- **Custom Columns, multiple Boards, due dates, priorities, tags.** One fixed Board is the point, and due dates or priorities would compete with age as the urgency signal.
