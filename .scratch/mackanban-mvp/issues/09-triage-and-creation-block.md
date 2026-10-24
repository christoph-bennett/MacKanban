# 09: Triage and the creation block

**What to build:** The creation gate on the New Card sheet. **Open** (3 or more free slots and no fully red Open Card): the sheet goes straight to title and notes. **Triage** (2 or fewer free slots, or any Open Card at Urgency 1): the sheet first shows the Open Card with the highest Urgency and offers **Start** (move to Doing, unavailable with a reason when Doing is at the WIP Limit), **Discard** and **Keep**. Any of these then continues to title and notes. Closing the sheet counts as **dismissed**. Every Triage appends a Triaged event on the triaged Card with its outcome, alongside the usual Moved or Discarded event. **Blocked** (0 or fewer free slots): the sheet explains ("Capacity 7, Open Cards 9: finish or Discard 3 Cards") and offers no way to create. Each blocked attempt appends a Creation Blocked Board Event with the Capacity and Open Card count. Undoing a Triage start or Discard also removes its Triaged event.

**Blocked by:** 04, 08

**Status:** done

- [x] The gate is open, Triage or blocked exactly as described, and Triage shows the Card with the highest Urgency
- [x] Start, Discard and Keep work, Start is unavailable with a reason at the WIP Limit, and Keep changes no Urgency
- [x] Every Triage records one Triaged event with outcome started, discarded, kept or dismissed
- [x] Blocked shows the explanation, can't create, and records one Creation Blocked event per attempt
- [x] The Board refuses create when blocked, even if called directly
- [x] Board tests: gate states and thresholds, Triage choosing the highest Urgency, Triaged and Creation Blocked events, create refused when blocked

**Notes from implementing:**
- Board API: `creationGate()` is a pure query (`open`, `triage(Card)`, `blocked(capacity:openCards:)`); ticket 11's menu bar can poll it. `attemptCreation()` is what the New Card button calls: it returns the gate and records the Creation Blocked event only when blocked, so the app can't record a block that isn't there. `triage(_:outcome:)` records the Triaged event after the Moved or Discarded one, in one save, and returns a `Change` only for started and discarded.
- Blocked wins over Triage. On a tie in Urgency, Triage shows the first in display order (Backlog's oldest before Doing). Triage of a Card in Doing offers Start greyed out with "The Card is already in Doing."
- `createCard` refuses with `creationBlocked` and records nothing; the user-facing attempt is recorded by `attemptCreation()`. The message ("Capacity 7, Open Cards 9: finish or Discard N Cards.") counts how many of the most urgent Open Cards must go to bring back one free slot, including the aging each takes with it (from the review: plain Open Cards − Capacity + 1 overcounted, and with no floor could ask for more Cards than the Board has). An Add Card refused because the Board became blocked while the sheet was open also records a Creation Blocked event.
- `Change` grew `companions` (the Triaged event), deleted along with it on undo. Triaged events, like Edited ones, don't count as a change of Column, so a kept Triage doesn't block undoing the move before it (ADR 0002 updated).
- The sheet: `NewCardSheetController` shows Triage or the blocked explanation, then embeds the existing `CardSheetViewController(.new)` for title and notes. Start is the default button when available. Cancel or Esc at Triage records dismissed. The triaged Card is tinted like on the Board (`UrgencyTint`, now shared).
- `SampleBoard` had to change: the old sample had more aging Cards than Capacity allows, which the Board now refuses. It now finishes "Finished chore" Cards to keep room (so Done is long), prints the gate it ends in (Triage, from the fully red "Quarterly report"), and `--blocked` fills Backlog until creating is blocked.
- `capacityHasNoFloor` had to build its 7 red Cards while Throughput still made room; same expected numbers.
- Checked by screenshot on sample Boards: Triage with Start unavailable (WIP Limit), Triage with Start available, blocked. Found on the way, not new with this ticket: SIGTERM doesn't quit MacKanban while a sheet is open, so `install.sh` can't restart it then.
- Checked by hand by Christoph on 2026-10-24: Start, Discard and Keep each continuing to title and notes; Cancel/Esc at Triage; ⌘Z after a Triage start or Discard (one step each, separate from the New Card); OK on the blocked sheet; the sheet resizing between steps.
- Review (medium) findings skipped, with reasons: undoing a Discard while blocked isn't a way around the block (undo only restores a state the Board was already in, and Capacity limits creating, not restoring); the gate is read when the sheet opens and not again (the sheet is modal on the only window that changes the Board, and `createCard` still enforces the block on save); Start for a Doing Card relies on `moveRefusal`, which is the Board's own answer and gives the right reason; a few extra Board passes per New Card press (the Board is small); the sheet's reason text uses the public threshold rather than a reason from the gate; undoing a creation also removes Triaged events on that Card (the Card never existed, ADR 0002).
