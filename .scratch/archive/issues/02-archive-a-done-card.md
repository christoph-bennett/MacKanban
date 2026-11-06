# 02: Archive a Done Card by hand

**What to build:** I can send a Done Card to the Archive before the Archive Delay is up: "Archive" in its context menu, or ⌘⌫ (the Card menu's item reads "Archive Card" while a Done Card is selected, "Discard Card" for an Open Card). It leaves the Board at once, shows up in an open Archive, and ⌘Z brings it back within 15 minutes. It stays in the Archive whatever the Archive Delay is later. Throughput doesn't change. Spec 0003 stories 1–3, 6–9, 11–17; ADR 0007.

**Blocked by:** 01 (Archive Delay setting)

**Status:** ready-for-agent

- [ ] New Card Event kind Archived, stored as a new value of the kind string (no schema change); the event log query returns it
- [ ] One archive rule used by Board state and the Archive query: a Done Card is archived if it has an Archived event or its Done visit is at least the Archive Delay old
- [ ] The Archived event changes no Column Visit, Column Age, Card Age or Throughput
- [ ] The Board's "archive a Card" records one Archived event and returns a Change; it refuses an Open Card, an already archived Card and a Sample Card with typed errors
- [ ] Undo deletes the Archived event within the 15-minute window; for undo the Archived event counts as the Card's latest placing event, so an older move can't be undone under it; Redo archives again at the current time
- [ ] A Done Card's context menu has "Archive" after a separator; Done Sample Cards still get no menu
- [ ] The Card menu's ⌘⌫ item switches title and action by the selected Card's Column ("Discard Card" / "Archive Card"); disabled while a sheet is open and for a selected Done Sample Card
- [ ] The selection moves after archiving as after a Discard
- [ ] Board tests: archive removes the Card from Done and puts it first among the Archive's Done Cards; Throughput and Capacity unchanged; the three refusals; undo within and after the window; an older move can't be undone after archiving; a hand-archived Card stays archived after lengthening the delay; the event log returns the Archived event
- [ ] Screenshot of a Done Card's context menu on a sample store
