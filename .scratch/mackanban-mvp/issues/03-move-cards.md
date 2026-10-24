# 03: Move Cards between Columns

**What to build:** Moving Cards with the allowed moves only: Backlog → Doing, Doing → Done and Doing → Backlog. Nothing leaves Done, and nothing skips Doing. Each move appends a Moved event (from, to). Moves work by drag and drop between Columns and by keyboard on the selected Card (e.g. ⌘→ / ⌘← for forward and back). Column Visits are replayed from Created and Moved events. Doing is ordered by Column Age (longest first) and Done newest first. Refused moves give a short explanation and change nothing.

**Blocked by:** 02

**Status:** done

- [x] Backlog → Doing, Doing → Done and Doing → Backlog work by drag and drop and by keyboard
- [x] Moves out of Done and Backlog → Done are refused with a typed error, shown as a message, and record no event
- [x] Every allowed move appends one Moved event with from and to
- [x] Doing is sorted by accumulated Column Age (longest first), Done newest first, Backlog oldest first
- [x] Board tests: allowed and refused moves, Moved events, Column Age adding up across visits (Doing 3 days, Backlog, Doing 2 days gives 5 days), display order per Column

**Notes from implementing:**
- Event timestamps are strictly increasing, at least 1 ms after the latest event, because the log has no sequence number (ADR 0002).
- Keyboard: ⌘→ and ⌘← (Card menu) move the clicked Card. Off the Board's edge the menu item is disabled; other refused moves show the Board's explanation as a sheet.
- Dropping a Card back on its own Column is ignored quietly.
- Checked by hand by Christoph on 2026-10-23.
- Amended on 2026-10-24 at Christoph's request: every drop the Board would refuse (Backlog → Done, out of Done, a full Doing) turns the Column red and bounces the Card back, instead of dropping and explaining in a sheet. Keyboard moves still explain. Checked by hand by Christoph on 2026-10-24.
