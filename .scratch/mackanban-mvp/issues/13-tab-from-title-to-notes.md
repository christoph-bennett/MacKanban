# 13: Tab in the Title goes to Notes

**What to build:** Bug fix, reported by Christoph on 2026-11-04: in the New Card sheet, Tab in the Title field doesn't move to Notes. Tab in the Title should put the insertion point in Notes, so the next keystrokes type there, as in any Mac dialog. This holds wherever the Card sheet appears: New Card on an open Board, New Card after a Triage decision (the title-and-notes step replaces the Triage step in the same sheet), and Edit. Shift-Tab from Notes goes back to the Title.

Ticket 06 (2026-11-03) recorded Title → Notes as working with synthesized key events, but only Tab *out of* Notes was checked by hand. Find the real cause first (likely the key view loop of the title-and-notes step embedded in the New Card sheet) and check it with real Tab presses by hand, not only synthesized events.

**Blocked by:** none

**Status:** ready-for-agent

- [ ] New Card on an open Board: Tab in the Title moves to Notes, and typing lands in Notes
- [ ] New Card after Triage (Start, Discard or Keep): the same
- [ ] Edit: the same
- [ ] Shift-Tab in Notes moves back to the Title in all three
- [ ] The rest of the order from ticket 06 still holds with the system's keyboard navigation on (Title → Notes → Cancel → Save when enabled → Title) and off (Title ↔ Notes)
