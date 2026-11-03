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
- Amended on 2026-11-03 at Christoph's request (spec story 54): Esc deselects the selected Card; with nothing selected it closes the Board window (like ⌘W) and, if no other MacKanban window (Archive, Settings) is still open, minimized ones included, hides MacKanban so the previous app comes back to the front. Sheets and drags take Esc first. Esc is now the only way to deselect; clicking an empty spot in a Column still doesn't. Checked with synthesized Esc key events: select, Esc (deselected), Esc (closed, then hidden); with Settings open the Board closes and MacKanban stays active. Checked by hand by Christoph on 2026-11-03; he isn't yet sure he wants two presses when a Card is selected.
- Amended on 2026-11-03 at Christoph's request (story 54 rewritten): Esc closes the Board window in one press even with a Card selected; it no longer deselects (deselecting had no use: nothing on the Board needs "no Card selected"). The selection survives closing. Nothing deselects by keyboard or click now. Checked by hand by Christoph on 2026-11-03.
- Amended on 2026-11-03 at Christoph's request (spec story 7): a Card's context menu offers the moves its Column allows, with no separators or shortcuts: Edit… (or Open… on Done; not on Sample Cards), then Move to Doing (Backlog) or Move to Done and Move to Backlog (Doing), then Discard. Done Cards offer only Open…; a Done Sample Card has no menu. Move to Doing stays enabled at the WIP Limit; a refusal shows the same sheet as ⌘→. The menu asks the Board which moves its Column allows (`Board.moveTargets(from:)`, forward first, tested in MoveTests) and runs the same move as a drop. Checked with a temporary hook that printed each menu and performed the move items on a scratch Board (refused move into full Doing showed the sheet; allowed move went through) and on a Board with Sample Cards.
