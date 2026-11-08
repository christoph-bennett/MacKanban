# 01: Restore from the Archive's context menu

**What to build:** A Discarded row in the Archive gets a context menu with "Restore"; Done rows and Sample Cards get none. Restoring puts the Card back in Backlog, whichever Column it was Discarded from, with its title, notes, Card Age and Column Age unchanged; it leaves the Archive and shows on the Board at once, counts toward Capacity from then on, and ⌘Z takes the Restore back within 15 minutes. A Restore needs room for the Card's whole cost: the drop in free slots it would cause, counted as Capacity counts (one slot plus its Urgency, rounded down). Without room, a sheet on the Archive says why, with the numbers: "No room to restore “<title>”. It's <age> old, so it takes up the room of <n> Cards: 1 for the Card and <urgency> for its age. The Board has room for <free>. Finish or Discard <k> Card(s) first." (a fresh Card: "It takes up the room of 1 Card."). A refused Restore records nothing. Spec 0005 stories 1, 2, 4–15, 17–19, 23–29; ADR 0008.

The Board decides with a gate beside the creation gate: open, Triage, or blocked, judged by the free slots left after the Restore (blocked below zero; Triage at one or fewer, or when the most urgent Open Card is fully red). Triage from the Archive comes in 02; until then, when the gate says Triage, the Restore is refused with a short sheet ("Capacity is nearly used up: restoring needs a Triage, which comes in a later version.") so it can never go around Capacity.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] "Restore" in the context menu of Discarded rows only; no menu on Done rows or Discarded Sample Cards
- [x] A restored Card is in Backlog with its title, notes and ages unchanged, out of the Archive, on the Board at once, and counted by Capacity; Throughput unchanged
- [x] A Card Discarded from Doing lands in Backlog; its Doing Column Age is unchanged if it's started again
- [x] Discard, Restore, Discard again: the Archive shows it once, with the last Discard's date
- [x] ⌘Z within 15 minutes puts it back in the Archive as Discarded; after 15 minutes it doesn't
- [x] The cost is 1 for a fresh Card and 2 for a fully red one, rounding included; the refusal shows the numbers and how many Cards to finish or Discard, counted as the creation block counts them
- [x] A refused Restore records no Card Event or Board Event (no Creation Blocked)
- [x] Until 02: a Restore that would need a Triage is refused, never done without it
- [x] Board tests: restore of Discarded, Done, Open and Sample Cards; ages; Archive query; Capacity; Undo inside and after the window; the gate open, Triage and blocked at the boundaries, with rounding; cost and cards-to-free
- [ ] Checked on a sample store with real input: restore with room, a refusal, ⌘Z; Christoph checks by hand (sample store done)

**Notes from implementing:**
- Board: a Restored Card Event (a new kind value, no schema change) starts a new Backlog visit, so the Card is an Open Card again, Card Age runs from its creation and Doing Column Age adds up as always. A Card is Discarded while its last visit has ended without a new one; the Archive and Capacity read the same visits. `restoreGate` gives the outcome (open, Triage, blocked with the cards to free), the cost in slots, the Card's Urgency and age, and the free slots now; `restore` refuses Open, Done and Sample Cards, a blocked Restore, and one that needs a Triage unless the caller says it happened (for ticket 02). Undo deletes the Restored event within 15 minutes.
- Archive window: "Restore" in the context menu of Discarded rows (not Sample Cards). With room, the Card is restored and the Board reloads, which reloads the Archive; ⌘Z and ⌘⇧Z in the Archive window undo and redo it, and a redo goes through the gate again like a click. Without room, a sheet with the numbers ("No room to restore “Learn Rust”. It's 34 days old, so it takes up the room of 2 Cards: 1 for the Card and 1,0 for its age. The Board has no room left. Finish or Discard 1 Card first."); the decimal follows the system's number format, as the dates do. When the gate says Triage, the interim sheet "Capacity is nearly used up" (until 02).
- Tests: 15 Board tests (restore, refusals, ages, Discarded from Doing, Discard again, Undo inside and after 15 minutes, the gate open/Triage/blocked at its boundaries, a fully red Open Card, rounding of the cost, nothing recorded on a refusal, Capacity and Throughput after a Restore, the Triage refusal). 136 tests pass.
- Checked on sample stores with real input (cliclick right-click, keystrokes): the normal sample shows the interim Triage sheet (fully red Open Cards); after Discarding those three, restoring "Learn Rust" took the Board from "5 of 16" to "6 of 15" (cost 2), ⌘Z put it back, ⌘⇧Z restored it again; a `--blocked` store showed the refusal above.
- Review (medium) fixes: the Board itself refuses a Restore that needs a Triage (a redo or a later button can't go around it); a redo goes through the gate and shows the same sheets; one reload instead of two; "Finish or Discard 0 Cards" can't appear; the visits comment mentions Restored. Kept: Undo of a Restore lives in the Archive window, where it's done, so ⌘Z in the Board window doesn't take it back; the Archive's undo registration is its own small copy of the Board window's.
- With fully red Cards on the Board, a Restore ends in the interim Triage sheet until 02 is done; on a real Board that's the usual case.
- Christoph's hand check still to come.
