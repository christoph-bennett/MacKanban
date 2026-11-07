# 02: Archive a Done Card by hand

**What to build:** I can send a Done Card to the Archive before the Archive Delay is up: "Archive" in its context menu, or ⌘⌫ (the Card menu's item reads "Archive Card" while a Done Card is selected, "Discard Card" for an Open Card). It leaves the Board at once, shows up in an open Archive, and ⌘Z brings it back within 15 minutes. It stays in the Archive whatever the Archive Delay is later. Throughput doesn't change. Spec 0003 stories 1–3, 6–9, 11–17; ADR 0007.

**Blocked by:** 01 (Archive Delay setting)

**Status:** done

- [x] New Card Event kind Archived, stored as a new value of the kind string (no schema change); the event log query returns it
- [x] One archive rule used by Board state and the Archive query: a Done Card is archived if it has an Archived event or its Done visit is at least the Archive Delay old
- [x] The Archived event changes no Column Visit, Column Age, Card Age or Throughput
- [x] The Board's "archive a Card" records one Archived event and returns a Change; it refuses an Open Card, an already archived Card and a Sample Card with typed errors
- [x] Undo deletes the Archived event within the 15-minute window; for undo the Archived event counts as the Card's latest placing event, so an older move can't be undone under it; Redo archives again at the current time
- [x] A Done Card's context menu has "Archive" after a separator; Done Sample Cards still get no menu
- [x] The Card menu's ⌘⌫ item switches title and action by the selected Card's Column ("Discard Card" / "Archive Card"); disabled while a sheet is open and for a selected Done Sample Card
- [x] The selection moves after archiving as after a Discard
- [x] Board tests: archive removes the Card from Done and puts it first among the Archive's Done Cards; Throughput and Capacity unchanged; the three refusals; undo within and after the window; an older move can't be undone after archiving; a hand-archived Card stays archived after lengthening the delay; the event log returns the Archived event
- [x] Screenshot of a Done Card's context menu on a sample store (checked by a TEMP hook printing the menus instead, see Notes)

**Notes from implementing:**
- Board: `archiveCard(_:)` records an Archived Card Event and returns a Change. Refusals: `cardNotFound` for a Discarded Card, `cardIsNotDone` for an Open Card, `cardIsArchived` (by hand or past the delay), `sampleCardCantBeArchived`. The archive rule stays in one place: the visits replay marks the Done visit an Archived event follows (`archivedByHand`), and `isArchived` reads that or the Archive Delay. An Archived event before a later move wouldn't count, so a future restore can't leave a stale mark. Column Visits, ages and Throughput ignore it.
- Undo: the Archived event counts as the Card's latest placing event, so an older move can't be undone under it, and the archive itself can. Undoing an archive is refused (`archiveDelayIsUp`) when the Card has passed the Archive Delay since, because it wouldn't come back. Redo archives again; if the delay took the Card in the meantime, Redo just reloads instead of showing "already in the Archive".
- App: a Done Card's context menu has "Archive" after a separator (Sample Cards still get no menu). The Card menu's ⌘⌫ item (`discardOrArchiveCard`) reads "Archive Card" for a Done Card and "Discard Card" for an Open Card, disabled for a Done Sample Card and while a sheet is open. Discard and Archive share one helper, which also refuses while a sheet is open, so the context menu and ⌘⌫ behave the same.
- Tests: new `ArchiveByHandTests` (12 scenarios: leaves the Board with Capacity unchanged, the event, dated by the Done date, stays archived after lengthening the delay, the refusals, undo within and after the window, undo refused once the delay is up, no older move undone under it, archive again after undo). 99 tests pass.
- Review (medium) fixes: undo past the delay is refused instead of reporting success while the Card stays archived; Redo after the delay is quiet; the Archived mark comes from the visits replay (one pass, ordered) instead of a second scan of the events; Discard and Archive share one helper with the sheet guard. The review's "double reload" didn't apply (`selectedCard` has no observer), but the explicit clear went anyway: the reload drops a selection that left the Board.
- Checked on a sample store with a TEMP hook (since removed): the context menus read Backlog "Edit…, Move to Doing, ---, Discard", Doing "Edit…, Move to Done, Move to Backlog, ---, Discard", Done "Open, ---, Archive"; ⌘⌫ reads "Discard Card" for Backlog and Doing and "Archive Card" for Done, all enabled; Archive from the context menu and from ⌘⌫ take the Card off Done into the Archive and clear the selection; the Undo menu says "Undo Archive"; Undo and Redo work. In the hook, two quick operations undid together, and two Discards did the same: NSUndoManager groups by event, and the hook had no real events, so Christoph checks single-step Undo by hand. No screenshot of the context menu: the terminal can't right-click (no Accessibility).
