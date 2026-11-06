# 03: Archive All Done Cards

**What to build:** "Archive All Done Cards" in the Card menu (after the ⌘⌫ item, no shortcut) and in every Done Card's context menu clears Done in one go, without a confirmation, skipping Sample Cards. One ⌘Z brings them all back. Spec 0003 stories 4, 5, 10.

**Blocked by:** 02 (Archive a Done Card by hand)

**Status:** ready-for-agent

- [ ] The Board's "archive all Done Cards" records an Archived event for every Done Card on the Board except Sample Cards, all in one Change (the other events as companions); it refuses when there's nothing to archive
- [ ] One undo reverts all of them; Redo archives them again
- [ ] The menu items are disabled when Done is empty or holds only Sample Cards, and while a sheet is open
- [ ] No confirmation dialog
- [ ] Board tests: archives every non-Sample Done Card and leaves Sample Cards; refused with nothing to archive; one undo brings all back to Done
