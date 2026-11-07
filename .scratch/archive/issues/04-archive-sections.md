# 04: Archive window with Done and Discarded sections

**What to build:** The Archive window shows two sections, Done first, then Discarded, each with a heading and each newest first, instead of one mixed list with an Outcome column. Columns: Card, Created, Ended (the section heading says whether that's finished or Discarded). Empty sections are hidden. Keyboard use and read-only opening stay as they are. Spec 0003 stories 26–31, 35–38.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The Board's Archive query returns Done entries and Discarded entries separately, each newest first; a Done entry is dated and sorted by when it entered Done
- [x] The window shows group rows "Done" and "Discarded" (not selectable, skipped by ↑↓), columns Card | Created | Ended, no Outcome column
- [x] A section with no Cards is hidden; "Nothing in the Archive yet." when both are empty
- [x] Return and double-click open a Card read-only as today; Esc closes; the selected Card stays selected across reloads; reloads after Board changes and once a minute while open
- [x] VoiceOver announces the section names
- [x] Board tests: the split and the order of both lists (extending the existing archive tests)
- [x] Screenshots on a sample store: both sections; only one section; empty Archive

**Notes from implementing:**
- Board: `archive()` returns an `Archive` with `done` and `discarded`, each the most recently ended first; a Done Card is dated and sorted by when it entered Done, also when archived by hand. `ArchivedCard` lost its `outcome`: the list it's in says it (review). `Archive.all` gives both, Done first.
- Window: one table with group rows "Done" and "Discarded" (a `Section` enum gives the title and the order), not selectable, so the arrow keys pass over them; the Done heading stays pinned at the top while scrolling (AppKit's floating group rows). Columns Card | Created | Ended, no Outcome. An empty section isn't shown; "Nothing in the Archive yet." when both are empty. A Card opens read-only by its section ("Done Card" / "Discarded Card"). VoiceOver reads a heading as "Done, section heading" (role description on its text field).
- Tests: the split and both orders, including a Card archived by hand sorted by its Done date; existing archive tests moved to the two lists. 109 tests pass.
- Checked with real input on a sample store (cliclick and System Events, aborting whenever MacKanban wasn't in front; VLC took the front twice, nothing was sent, and the run was repeated after Christoph quit VLC): ↓ with nothing selected lands on the first Done Card; ↑ there stays; ↓ from the last Done Card skips the "Discarded" heading; Return opens "Discarded Card" / "Done Card", Esc closes the sheet, a second Esc the window. Screenshots: both sections (top and bottom), only Done (29 rows: the heading and 28 Cards, checked in the accessibility tree), and the empty Archive.
- Review (medium) fixes: the heading's VoiceOver text (was only "Done"); `outcome` removed instead of kept beside the split; one pass to split; a `Section` enum instead of heading strings, also deciding the sheet mode; the heading cell's ID apart from the column IDs; `Archive.all`. The worry that ↓ might stick on a heading row was checked by hand and doesn't apply.
- Checked by hand by Christoph on 2026-11-07.
