# Spec 0005 — Restore a Discarded Card from the Archive

Status: ready-for-agent

Vocabulary follows [GLOSSARY.md](../../GLOSSARY.md) (Restore, Discard, Archive, Capacity, Triage, Card Age, Column Age). Decisions: [ADR 0008](../adr/0008-restore-discarded-cards.md); it leaves [ADR 0001](../adr/0001-capacity-and-urgency-rules.md) untouched and builds on [ADR 0002](../adr/0002-core-data-event-log.md) (event log, Undo) and [ADR 0007](../adr/0007-archived-event-for-manual-archiving.md) (the Archive). Designed with Christoph on 2026-11-08 (grill about the BACKLOG Inbox item, raised when a Card was Discarded by mistake on 2026-11-06).

## Problem Statement

When I Discard a Card by mistake and notice it after Undo's 15 minutes, it's gone for good: the Archive shows it, but I can't bring it back. All I can do is create it again, which loses its history and makes old work look new. And whatever way back there is mustn't become a way around my Board's rules: a Card that comes back has to bring its age and its cost with it.

## Solution

A Discarded Card in the Archive can be restored: from its row's context menu, or with a Restore button in its read-only sheet. It goes back to Backlog as an Open Card, with its Card Age and Column Age unchanged, so an old Card comes back as red as it would have been. It needs room like a new Card, but for its whole cost: a fully red Card takes up the room of two. When there's room, it's back at once; when Capacity is nearly used up, the Board comes forward with Triage first, as when creating; when there's no room, the Archive says why, with the numbers, and what to do. The button's hover text says the cost beforehand. Undo takes a Restore back within 15 minutes. Done Cards and Sample Cards can't be restored.

## User Stories

Restoring

1. As a user, I want to restore a Discarded Card from the Archive, so that a Card Discarded by mistake comes back after Undo's 15 minutes are over.
2. As a user, I want "Restore" in the context menu of a Discarded row in the Archive, so that I can bring a Card back without opening it.
3. As a user, I want a Restore button in a Discarded Card's read-only sheet, beside Close, so that I can bring it back after reading it.
4. As a user, I want a restored Card to land in Backlog, whichever Column I Discarded it from, so that the WIP Limit never stands in the way and I start it when I'm ready.
5. As a user, I want a restored Card to leave the Archive and show up on the Board at once, so that I see it worked.
6. As a user, I want the Archive window to stay open after a Restore, so that I can restore another Card or keep looking.
7. As a user, I want the restored Card's title and notes exactly as they were, so that nothing is lost.

Ages and rules

8. As a user, I want a restored Card to keep its Card Age, including the time it spent in the Archive, so that Discard and Restore can't make old work look fresh (ADR 0001).
9. As a user, I want its Column Age in Doing to add up across visits as always, so that a later start in Doing continues where it left off.
10. As a user, I want a restored Card's Urgency to count toward Capacity from the moment it's back, like any Open Card's.
11. As a user, I want Throughput to stay as it was, since a Discarded Card never counted.
12. As a user, I want a restored Card to be like any other Open Card afterwards: I can move, edit, Discard and Triage it.
13. As a user, I want to be able to Discard a restored Card again, and see it in the Archive once, with the date of its last Discard.

Room for a Restore

14. As a user, I want a Restore to need room for the Card's whole cost, one slot plus its Urgency counted as Capacity counts it, so that one Restore can't put more on the Board than Capacity allows.
15. As a user, I want a fresh Card to need the room of one Card and a fully red one the room of two, so that the cost follows the Card's age.
16. As a user, I want the Restore button's hover text to say the cost beforehand ("Takes up the room of 2 Cards (25 days old)", "Takes up the room of 1 Card"), so that a refusal doesn't surprise me.
17. As a user, I want the Restore action to be available even when there's no room, so that clicking it tells me why instead of a greyed-out button that doesn't.
18. As a user, when there's no room, I want the Archive to say so with the numbers and what to do, e.g. "No room to restore “Plan the garden”. It's 25 days old, so it takes up the room of 2 Cards: 1 for the Card and 1.0 for its age. The Board has room for 1. Finish or Discard 1 Card first.", so that I understand why a free slot on the Board isn't enough.
19. As a user, I want the number of Cards to finish or Discard counted as the creation block counts it, so that both say the same thing.
20. As a user, when Capacity is nearly used up after the Restore, I want the Board to come forward with Triage first, as when creating a Card, so that restoring doesn't skip the step creating would take.
21. As a user, I want the Card to be restored right after the Triage (if there's still room), so that I don't have to start over from the Archive.
22. As a user, I want dismissing the Triage to restore nothing, as dismissing it when creating creates nothing.
23. As a user, I want a refused Restore not to count as Creation Blocked, so that a later dashboard doesn't mix two different things.

Undo and history

24. As a user, I want ⌘Z to take a Restore back within 15 minutes, putting the Card back in the Archive as Discarded, so that a Restore by mistake is as easy to fix as any other change.
25. As a user, I want the Card's history to keep its Discard and add the Restore, so that a later dashboard sees what really happened.

Limits

26. As a user, I want no Restore for Done Cards, so that finished work can't be finished twice; unfinished work becomes a new Card.
27. As a user, I want no Restore for Discarded Sample Cards, as they offer no actions in the Archive.
28. As a user, I want no time limit on Restore, since a restored Card brings its age and cost anyway.
29. As a user, I want a MacKanban on a sample store to restore only within that store, so that trying it never touches my real Board.
30. As a VoiceOver user, I want the Restore button and menu item, the cost and the refusal read out, so that I can restore without seeing the screen.

## Implementation Decisions

- **Board (KanbanCore)**: a Restore of a Card by id, refused for a Card that isn't Discarded (on the Board, Done, or a Sample Card). It records a Restored Card Event, a new value of the existing kind string (no schema change, ADR 0002), and the Card is in Backlog from then on: a new Backlog visit starts at the Restore.
- **Discarded check**: a Card is Discarded when its last Discarded event isn't followed by a Restored event. Board queries, the Archive query and Capacity all use that one check.
- **A gate for Restore** beside the creation gate, with the same three outcomes: open, Triage of the most urgent Open Card, or blocked. It's judged by the free slots left after the Restore, computed as Capacity computes them (rounded down, capped, with the Card's Urgency at that moment): blocked when fewer than zero would be left; Triage when one or fewer would be left, or when the most urgent Open Card is fully red, the same thresholds creating uses (creating triages at two or fewer free slots before the new Card, i.e. one or fewer after it). The blocked outcome carries what the refusal says: the Card's cost in slots, its Urgency, its age, the free slots now, and how many of the most urgent Open Cards to finish or Discard for room, counted as the creation block counts them.
- **The cost** a hover text and a refusal show is the drop in free slots the Restore would cause (1 for a fresh Card, 2 for a fully red one, rounding included), from the same computation as the gate.
- **Undo**: a Restore returns a Change like other actions; undoing deletes the Restored event within the undo window.
- **Archive window**: a context menu on Discarded rows with "Restore" (none on Done rows or Sample Cards); the Discarded Card's read-only sheet gets a "Restore" button beside Close, with the cost as its hover text. Return keeps closing the sheet; Restore is not the default button.
- **Triage from the Archive**: like the New Card hotkey, the Board comes forward and shows the Triage sheet; after an outcome that leaves room, the Card is restored instead of the New Card sheet appearing. The gate is checked again after the Triage, since starting a Card can change its Urgency.
- **Refusal**: a sheet on the Archive window with the text of story 18, and an OK button.
- **No Board Event** for a refused Restore.

## Testing Decisions

- Tests go through the Board's public interface, as in the existing Board tests: restore, the gate, the Archive query, Board queries, Capacity and Undo, with the test clock. Good tests state behaviour a user would notice ("a Card Discarded three weeks ago comes back fully red"), not how events are stored.
- Cases: restoring puts the Card in Backlog and takes it out of the Archive; Card Age and Doing Column Age unchanged after a Restore; Discarded from Doing still lands in Backlog; Capacity counts it at once; Throughput unchanged; Done Cards, Open Cards and Sample Cards are refused; Discard, Restore, Discard again shows once in the Archive with the last date; Undo within 15 minutes puts it back, after 15 minutes it doesn't; the gate is open, Triage or blocked at the boundaries, with rounding (a Card whose Urgency tips Capacity down by one more slot); the cost is 1 for a fresh Card and 2 for a fully red one; the cards-to-free number matches the creation block's.
- Prior art: the archive-by-hand tests, the Triage and creation-gate tests, the Undo tests.
- The windows (context menu, button, hover text, refusal sheet, Triage from the Archive) are checked by hand on a sample store with real input, light and dark, and with VoiceOver's accessibility tree.

## Out of Scope

- Restoring Done Cards ("reopen").
- Restoring several Cards at once.
- Restoring to Doing or to the Column the Card was Discarded from.
- Restoring Sample Cards.
- Showing in the Archive that a Card was restored before; the history keeps it for a dashboard.
- A time limit on Restore.

## Further Notes

- The first real case: a Card Discarded by mistake on 2026-11-06.
- Tickets go in `.scratch/restore/issues/`.
