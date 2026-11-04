# 15: A click beside the Cards clears the selection

**What to build:** Asked for by Christoph on 2026-11-04. While a Card is selected, in any Column, a click (left or right) anywhere in the Board window that isn't on a Card clears the selection: the empty part of a Column, a Column's header and count, the gaps between Columns and the window's margins. The title bar (Capacity gauge, + button) doesn't. This reverses the 2026-11-03 note in ticket 03 that nothing deselects a Card.

Unchanged: a click on a Card or its pencil selects that Card, as before. Esc still closes the Board window and keeps the selection (story 54). With nothing selected, the Card commands behave as they already do then: the Card menu's items are off, Return opens nothing, ⌘→ and ⌘← beep. The Board (model, events) isn't involved: the selection is the window's state only.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] With a Card selected in Backlog, Doing or Done, a left click on an empty spot of any Column (including another Column) clears the selection; no Card shows as selected
- [ ] The same for a click on a Column's header or count, on a gap between Columns and on the window's margin
- [ ] A right click on any of those spots clears it too
- [ ] A click in the title bar (Capacity gauge, + button) leaves the selection alone
- [ ] A click on another Card selects that Card; a click on a Card's pencil still opens it
- [ ] After clearing: the Card menu's Card items are off, Return opens nothing, ⌘→ and ⌘← beep
- [ ] Esc still closes the window and keeps a selection
- [ ] Spec: a new story 55; ticket 03: a dated note; `docs/mackanban-handoff.md`'s "Nothing deselects a Card" entries corrected
