# 15: A click beside the Cards clears the selection

**What to build:** Asked for by Christoph on 2026-11-04. While a Card is selected, in any Column, a click (left or right) anywhere in the Board window that isn't on a Card clears the selection: the empty part of a Column, a Column's header and count, the gaps between Columns and the window's margins. The title bar (Capacity gauge, + button) doesn't. This reverses the 2026-11-03 note in ticket 03 that nothing deselects a Card.

Unchanged: a click on a Card or its pencil selects that Card, as before. Esc still closes the Board window and keeps the selection (story 54). With nothing selected, the Card commands behave as they already do then: the Card menu's items are off, Return opens nothing, ⌘→ and ⌘← beep. The Board (model, events) isn't involved: the selection is the window's state only.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] With a Card selected in Backlog, Doing or Done, a left click on an empty spot of any Column (including another Column) clears the selection; no Card shows as selected
- [x] The same for a click on a Column's header or count, on a gap between Columns and on the window's margin
- [x] A right click on any of those spots clears it too
- [x] A click in the title bar (Capacity gauge, + button) leaves the selection alone
- [x] A click on another Card selects that Card; a click on a Card's pencil still opens it
- [x] After clearing: the Card menu's Card items are off, Return opens nothing, ⌘→ and ⌘← beep
- [x] Esc still closes the window and keeps a selection
- [x] Spec: a new story 55; ticket 03: a dated note; `docs/mackanban-handoff.md`'s "Nothing deselects a Card" entries corrected

**Notes from implementing (2026-11-04):**
- A click no Card takes travels up the responder chain from the view under the pointer (Column, its labels, scroll view, the Board's stack view) to the Board's view controller, which clears the selection on mouse down, left or right. Cards keep handling their own clicks and context menu; the title bar isn't part of the Board view. Nothing in the Board model changes.
- Checked with synthesized mouse events on a sample Board: with a Card selected in each Column, clicks on the empty part of the same and another Column, a Column title, Doing's count, the gap between Columns, the left and bottom margins, and right clicks on an empty Column, a title and a gap all clear it; a click on another Card selects that Card; left and right clicks in the title bar leave the selection alone. Card commands with nothing selected weren't re-checked: their enabling already depends only on whether a Card is selected.
- Code review (medium) fixes: a right click on a Card with no context menu (a Done Sample Card) used to go on up to the Board and clear the selection it had just made; a Card now keeps its right clicks, so it stays selected. Selecting and clearing share one path, and a clearing click also puts the Board back in the responder chain for the Card menu. Rechecked: a right click on a Done Sample Card selects it; the cases above (synthesized clicks with the window key).
- Skipped from the review: a click on a Column's scroller (only shown while scrolling, or always with "Show scroll bars: Always") scrolls and doesn't deselect. That's the scroller's own click, as in Finder; catching every click at the window instead would be more code for a spot nobody clicks to deselect.
- Checked by hand by Christoph on 2026-11-04.
