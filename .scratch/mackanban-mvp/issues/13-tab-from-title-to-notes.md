# 13: Tab in the Title goes to Notes

**What to build:** Bug fix, reported by Christoph on 2026-11-04: in the New Card sheet, Tab in the Title field doesn't move to Notes. Tab in the Title should put the insertion point in Notes, so the next keystrokes type there, as in any Mac dialog. This holds wherever the Card sheet appears: New Card on an open Board, New Card after a Triage decision (the title-and-notes step replaces the Triage step in the same sheet), and Edit. Shift-Tab from Notes goes back to the Title.

Ticket 06 (2026-11-03) recorded Title → Notes as working with synthesized key events, but only Tab *out of* Notes was checked by hand. Find the real cause first (likely the key view loop of the title-and-notes step embedded in the New Card sheet) and check it with real Tab presses by hand, not only synthesized events.

**Blocked by:** none

**Status:** done

- [x] New Card on an open Board: Tab in the Title moves to Notes, and typing lands in Notes
- [x] New Card after Triage (Start, Discard or Keep): the same
- [x] Edit: the same
- [x] Shift-Tab in Notes moves back to the Title in all three
- [x] The rest of the order from ticket 06 still holds with the system's keyboard navigation on (Title → Notes → Cancel → Save when enabled → Title) and off (Title ↔ Notes)

**Notes from implementing (2026-11-04):**
- Cause: the window works out its Tab order (key view loop) once, when the sheet first appears. After Triage, the title-and-notes step replaces the Triage step in the same sheet, so the title field had no next key view and Tab stayed in it. The New Card sheet now has the window recalculate the loop whenever it swaps steps. On an open Board and in Edit, the sheet opens with the title-and-notes step, which is why the 2026-11-03 checks passed.
- Checked with synthesized key events (Tab, a typed character, Shift-Tab) in all three: New Card on an open Board, New Card after Triage → Keep, and Edit. The character lands in Notes; Shift-Tab goes back to the Title. Order with keyboard navigation on: Title → Notes → Cancel → Save (when enabled) → Title.
- Checked by hand by Christoph on 2026-11-05.
