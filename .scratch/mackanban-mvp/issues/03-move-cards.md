# 03: Move Cards between Columns

**What to build:** Moving Cards with the allowed moves only: Backlog → Doing, Doing → Done and Doing → Backlog. Nothing leaves Done, and nothing skips Doing. Each move appends a Moved event (from, to). Moves work by drag and drop between Columns and by keyboard on the selected Card (e.g. ⌘→ / ⌘← for forward and back). Column Visits are replayed from Created and Moved events. Doing is ordered by Column Age (longest first) and Done newest first. Refused moves give a short explanation and change nothing.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Backlog → Doing, Doing → Done and Doing → Backlog work by drag and drop and by keyboard
- [ ] Moves out of Done and Backlog → Done are refused with a typed error, shown as a message, and record no event
- [ ] Every allowed move appends one Moved event with from and to
- [ ] Doing is sorted by accumulated Column Age (longest first), Done newest first, Backlog oldest first
- [ ] Board tests: allowed and refused moves, Moved events, Column Age adding up across visits (Doing 3 days, Backlog, Doing 2 days gives 5 days), display order per Column
