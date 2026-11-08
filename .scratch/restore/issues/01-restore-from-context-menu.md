# 01: Restore from the Archive's context menu

**What to build:** A Discarded row in the Archive gets a context menu with "Restore"; Done rows and Sample Cards get none. Restoring puts the Card back in Backlog, whichever Column it was Discarded from, with its title, notes, Card Age and Column Age unchanged; it leaves the Archive and shows on the Board at once, counts toward Capacity from then on, and ⌘Z takes the Restore back within 15 minutes. A Restore needs room for the Card's whole cost: the drop in free slots it would cause, counted as Capacity counts (one slot plus its Urgency, rounded down). Without room, a sheet on the Archive says why, with the numbers: "No room to restore “<title>”. It's <age> old, so it takes up the room of <n> Cards: 1 for the Card and <urgency> for its age. The Board has room for <free>. Finish or Discard <k> Card(s) first." (a fresh Card: "It takes up the room of 1 Card."). A refused Restore records nothing. Spec 0005 stories 1, 2, 4–15, 17–19, 23–29; ADR 0008.

The Board decides with a gate beside the creation gate: open, Triage, or blocked, judged by the free slots left after the Restore (blocked below zero; Triage at one or fewer, or when the most urgent Open Card is fully red). Triage from the Archive comes in 02; until then, when the gate says Triage, the Restore is refused with a short sheet ("Capacity is nearly used up: restoring needs a Triage, which comes in a later version.") so it can never go around Capacity.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] "Restore" in the context menu of Discarded rows only; no menu on Done rows or Discarded Sample Cards
- [ ] A restored Card is in Backlog with its title, notes and ages unchanged, out of the Archive, on the Board at once, and counted by Capacity; Throughput unchanged
- [ ] A Card Discarded from Doing lands in Backlog; its Doing Column Age is unchanged if it's started again
- [ ] Discard, Restore, Discard again: the Archive shows it once, with the last Discard's date
- [ ] ⌘Z within 15 minutes puts it back in the Archive as Discarded; after 15 minutes it doesn't
- [ ] The cost is 1 for a fresh Card and 2 for a fully red one, rounding included; the refusal shows the numbers and how many Cards to finish or Discard, counted as the creation block counts them
- [ ] A refused Restore records no Card Event or Board Event (no Creation Blocked)
- [ ] Until 02: a Restore that would need a Triage is refused, never done without it
- [ ] Board tests: restore of Discarded, Done, Open and Sample Cards; ages; Archive query; Capacity; Undo inside and after the window; the gate open, Triage and blocked at the boundaries, with rounding; cost and cards-to-free
- [ ] Checked on a sample store with real input: restore with room, a refusal, ⌘Z; Christoph checks by hand
