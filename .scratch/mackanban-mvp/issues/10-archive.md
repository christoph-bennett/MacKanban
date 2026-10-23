# 10: Archive

**What to build:** Done Cards leave the Board 7 days after entering Done. This is computed from the Moved-to-Done event and never stored (there's no Archived event, ADR 0002). An Archive window (⌘⇧A and the Window menu) lists archived Done Cards and Discarded Cards, read-only, with their created date and their Done or Discarded date, newest first.

**Blocked by:** 03, 06

**Status:** ready-for-agent

- [ ] A Done Card disappears from the Board 7 days after entering Done, within a minute of that moment
- [ ] The Archive window lists archived Done Cards and Discarded Cards with their dates, newest first, and opens them read-only
- [ ] No event is written when a Card is archived
- [ ] Board tests: a Done Card visible at 6 days, archived at 7; Discarded Cards appear in the Archive query
