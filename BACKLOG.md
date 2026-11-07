# Backlog

Ideas and requirements not yet built. New items go to **Inbox**. Once triaged they move to **MVP** (and become a ticket in `.scratch/mackanban-mvp/issues/`), **Later**, or **Not planned** (with the reason). Vocabulary: [GLOSSARY.md](./GLOSSARY.md). MVP scope: [spec 0001](./docs/specs/0001-mvp.md).

## Inbox

- **Restore a Card from the Archive** back to the Board, e.g. a Card Discarded by mistake (2026-11-06). Open: where it goes (Backlog?), whether a restored Discarded Card is an Open Card again and costs Capacity, whether a restored Done Card loses its Throughput. Left out of spec 0003 (Archive), 2026-11-06.
- **"Show ages on Cards" also for the Backlog** (requested 2026-11-07). Open: what exactly. Backlog Cards already show their Card Age ("12d old") while the setting is on; only Done Cards have no age label. Possibly a separate switch per Column, or an age on Done Cards.

## MVP

Everything in [spec 0001](./docs/specs/0001-mvp.md), including **Sample Cards** (user stories 49–53, ADR 0005, ticket 12; grilled 2026-10-26).

## Later

- **Manual reordering ("planning order")** in Backlog and Doing, so I can plan which Cards to do first. The order is only a plan: it never affects Urgency or Capacity, and the default stays oldest first. Deferred 2026-10-23: fixed order first, see how it feels.
- **Global New Card hotkey** with a small quick-add panel from any app, going through Triage and the Capacity block like the sheet. Deferred 2026-10-23. A global hotkey that shows the Board came first (2026-11-05, [spec 0002](./docs/specs/0002-show-board-hotkey.md)); it brings in KeyboardShortcuts (ADR 0006), which this item would reuse. Asked for again 2026-11-07: as a second recorder in Settings > Shortcuts, beside Show Board.
- **Dashboard** of the Board's history: Throughput over time, how long Cards spend in each Column, Cards kept repeatedly in Triage, Creation Blocked frequency, WIP Limit changes. The MVP already records every Card Event and Board Event for it (ADR 0002). Requested 2026-10-23.
- **iCloud sync** via `NSPersistentCloudKitContainer`. The model is already CloudKit-ready (ADR 0002). Needs a Developer ID signature, an iCloud container and entitlements, plus a rule for merging conflicting Column Visits.

## Not planned

- **Notifications** (a Card turned red, Capacity dropped). The pressure applies when you come to add something, and nagging from outside the app is a different product. Decided 2026-10-23.
- **Configurable Urgency thresholds or Capacity formula.** Setting them loose would switch off the mechanism (ADR 0001).
- **Custom Columns, multiple Boards, due dates, priorities, tags.** One fixed Board is the point, and due dates or priorities would compete with age as the urgency signal.
