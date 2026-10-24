# 10: Archive

**What to build:** Done Cards leave the Board 7 days after entering Done. This is computed from the Moved-to-Done event and never stored (there's no Archived event, ADR 0002). An Archive window (⌘⇧A and the Window menu) lists archived Done Cards and Discarded Cards, read-only, with their created date and their Done or Discarded date, newest first.

**Blocked by:** 03, 06

**Status:** done

- [x] A Done Card disappears from the Board 7 days after entering Done, within a minute of that moment
- [x] The Archive window lists archived Done Cards and Discarded Cards with their dates, newest first, and opens them read-only
- [x] No event is written when a Card is archived
- [x] Throughput still counts a Card archived less than 14 days after it was finished (Capacity reads it from the history, ticket 08)
- [x] Board tests: a Done Card visible at 6 days, archived at 7; Discarded Cards appear in the Archive query

**Notes from implementing:**
- `Board.archiveDelay` (7 days) is a constant. `state()` leaves out a Done Card once its Done visit is 7 days old (at exactly 7 days it's archived). `archive()` returns `ArchivedCard`s (the Card, created, ended, outcome done or discarded), the most recently ended first. Nothing is written when a Card is archived.
- Throughput was already counted from the history (ticket 08); a test now pins that an archived Card still counts until 14 days after it was finished.
- The Archive window (⌘⇧A, Window menu) is a table: Card, Done or Discarded, Created, Done or Discarded date. Double-click or Return opens the Card read-only ("Done Card" or "Discarded Card"). It reloads when shown, after every Board change (a Discard shows up straight away), and once a minute while visible.
- `SampleBoard` now also Discards a Card ("Learn Rust") so the Archive shows both kinds.
- Review (medium) fixes: the archive rule lives in one place (`isArchived`), used by both `state()` and `archive()`; the Archive keeps the selected Card selected across reloads (new entries arrive at the top); a minimized Archive still reloads after Board changes; store errors show one alert at a time; the minute timer runs only while the Archive is open; the sample's timeline no longer ends in the future (the Discard reuses an existing step). Skipped: `archive()` doing its own full pass (the Board is small and it only runs while the Archive is open), and the separate `.discarded` sheet mode (one switch arm each, clearer than a heading parameter).
- Checked by screenshot on the sample Board: the Archive window, and Done on the Board showing only the last 7 days with the gauge unchanged.
- Checked by hand by Christoph on 2026-10-24: ⌘⇧A and the Window menu item, opening a Done and a Discarded Card from the Archive (double-click and Return), a Discard showing up in an open Archive window, a Done Card leaving the Board within a minute of turning 7 days old.
- Fixed after Christoph's first look: in an empty Archive, "Nothing in the Archive yet." sat on top of the column headers (it was inside the scroll view, which ignores the centring constraints). It now sits over the scroll view in a container. Empty and full Archive checked by screenshot.
- Changed on 2026-10-24 at Christoph's request: columns are Card, Created, Outcome (Done or Discarded, from the Card's events; was the second column, headed Outcome), Ended (when it was finished or Discarded, date and time; was headed Done or Discarded).
