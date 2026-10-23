# 07: Undo

**What to build:** ⌘Z right after creating, moving or Discarding a Card undoes it through `NSUndoManager`, and ⌘⇧Z redoes it. Undo calls the Board's revert operation, which deletes the event being reverted instead of appending a new one (ADR 0002): the Moved event for a move, the Discarded event for a Discard, and the Card with its events for a creation. The Card's ages are as if the slip never happened. Edits use the text fields' own undo. Board Events can't be undone.

**Blocked by:** 03, 06

**Status:** ready-for-agent

- [ ] ⌘Z undoes the last create, move or Discard, and ⌘⇧Z redoes it
- [ ] Undo deletes the reverted event and never appends one
- [ ] Undoing a creation removes the Card and its events
- [ ] Board tests: Doing for 3 days, moved to Done by mistake, undone, then 1 more day gives Column Age 4 days and no Done visit. Undone Discard and undone creation leave no trace in the event log
