# 07: Undo

**What to build:** ⌘Z right after creating, moving or Discarding a Card undoes it through `NSUndoManager`, and ⌘⇧Z redoes it. Undo calls the Board's revert operation, which deletes the event being reverted instead of appending a new one (ADR 0002): the Moved event for a move, the Discarded event for a Discard, and the Card with its events for a creation. The Card's ages are as if the slip never happened. Edits use the text fields' own undo. Board Events can't be undone.

**Blocked by:** 03, 06

**Status:** done

- [x] ⌘Z undoes the last create, move or Discard, and ⌘⇧Z redoes it
- [x] Undo deletes the reverted event and never appends one
- [x] Undoing a creation removes the Card and its events
- [x] Board tests: Doing for 3 days, moved to Done by mistake, undone, then 1 more day gives Column Age 4 days and no Done visit. Undone Discard and undone creation leave no trace in the event log

**Notes from implementing:**
- Undo works for 15 minutes after the change (`Board.undoWindow`), only while the change is still the Card's latest change of Column (edits don't count), and never past the WIP Limit. ADR 0002 updated.
- Redo runs the operation again at the current time; a re-created Card keeps its ID.
- Checked by hand by Christoph on 2026-10-23.
