# 03: Archive All Done Cards

**What to build:** "Archive All Done Cards" in the Card menu (after the ⌘⌫ item, no shortcut) and in every Done Card's context menu clears Done in one go, without a confirmation, skipping Sample Cards. One ⌘Z brings them all back. Spec 0003 stories 4, 5, 10.

**Blocked by:** 02 (Archive a Done Card by hand)

**Status:** done

- [x] The Board's "archive all Done Cards" records an Archived event for every Done Card on the Board except Sample Cards, all in one Change (the other Cards' Changes alongside it; see the notes); it refuses when there's nothing to archive
- [x] One undo reverts all of them (except Cards past the Archive Delay by then, see the notes); Redo archives them again
- [x] The menu items are disabled when Done is empty or holds only Sample Cards, and while a sheet is open
- [x] No confirmation dialog
- [x] Board tests: archives every non-Sample Done Card and leaves Sample Cards; refused with nothing to archive; one undo brings all back to Done

**Notes from implementing:**
- Board: `archiveAllDoneCards()` archives every Done Card a single Archive would accept (one shared rule, `archiveRefusal`: on the Board, in Done, not yet archived, not a Sample Card), newest first, and returns one Change; `nothingToArchive` when there's none. `hasDoneCardsToArchive()` answers the same question for the menu.
- One Change for several Cards: a Change's `companions` are events of its own Card, checked against that Card's history, so they couldn't carry other Cards' events. The other Cards' Changes go in a new `alongside` list instead, and `revert` checks each on its own Card before deleting anything. One undo brings all of them back. A Card that has passed the Archive Delay by then stays archived while the others come back; the undo is refused (`archiveDelayIsUp`) only if none can.
- App: "Archive All Done Cards" in the Card menu after the ⌘⌫ item (no shortcut) and in every Done Card's context menu after "Archive"; no confirmation; the undo menu reads "Undo Archive All". The Card menu item asks the store whether there's anything to archive, because Done on screen can be up to a minute old; it's off while a sheet is open. Redo after the delay took the Cards reloads quietly (also for Archive All).
- Tests: Archive All takes every Done Card and keeps Capacity; leaves Sample Cards; refused with nothing to archive (empty Done, or only Sample Cards); one undo brings all back; undo brings back those short of the delay, and is refused if none are; names the newest Done Card first; the menu question follows the delay; archive again after undo. 108 tests pass.
- Review (medium) fixes: partial undo instead of all-or-nothing when a Card passed the delay; quiet Redo for `nothingToArchive`; the menu asks the store, not the Cards on screen; one shared rule for Archive and Archive All; the fetch prefetches events; a fixed order (newest first) for the returned Change; the duplicated `shownCards` helper went away with the menu change.
- Checked on a sample store with a TEMP hook (since removed): the Card menu reads "Move to Next Column, Move to Previous Column, ---, Edit Card…, Discard Card, Archive All Done Cards"; a Done Card's context menu "Open, ---, Archive, Archive All Done Cards"; Archive All emptied Done (2 Cards), the item turned off, and one Undo brought both back.
