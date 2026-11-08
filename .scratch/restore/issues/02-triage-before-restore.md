# 02: Triage before a Restore

**What to build:** When Capacity would be nearly used up after a Restore, the Board comes forward with the Triage sheet, as with the New Card hotkey. After an outcome that still leaves room, the Card is restored at once, instead of the New Card sheet appearing; the gate is checked again after the Triage, since starting a Card can change its Urgency, and if there's no room any more the refusal from 01 shows. Dismissing the Triage restores nothing. This replaces 01's interim refusal. Spec 0005 stories 20–22; ADR 0008.

**Blocked by:** 01 (Restore from the Archive's context menu)

**Status:** done

- [x] A Restore with one or fewer free slots left after it, or with a fully red Open Card on the Board, brings the Board forward with the Triage sheet for the most urgent Open Card
- [x] Start, Discard or Keep in the Triage, then the Card is restored to Backlog; the Archive updates
- [x] Dismissing the Triage restores nothing and records nothing beyond what Triage records today
- [x] If the Triage leaves no room, the refusal shows instead of a Restore
- [x] Undo after a Triage and Restore takes back the Restore first, then the Triage outcome as today
- [x] 01's interim refusal is gone
- [x] Board test for the gate checked after a Triage outcome
- [x] Checked on a sample store with real input (one Triage per outcome, and a dismissal); Christoph checks by hand

**Notes from implementing:**
- When the gate says Triage, the Archive hands the Card to the Board, which comes forward (as for the New Card hotkey) with the New Card sheet's Triage step, headed "Before you restore “<title>”". After Start, Discard or Keep the sheet closes instead of going on to the title step, the gate is checked again, and the Card is restored, or the refusal from 01 shows on the Board. Cancel records Dismissed, as when creating, and restores nothing. 01's interim sheet is gone.
- The reason line says why: "Your most urgent Card is fully red. Decide about it first." when that's the cause, otherwise "“<title>” takes up the room of 2 Cards, which leaves 1 free. Decide about your most urgent Card first." (the creation wording would have said "nearly used up" with slots still free).
- Undo: the Restore goes into the shared history after the Triage outcome, so ⌘Z takes back the Restore first, then a Start or Discard. A redo goes through the gate again and shows the Triage again.
- Tests: three Board tests (Discard in the Triage opens the gate; after Keep the Restore needs `afterTriage`; room gone by the time the Triage is done means blocked). 139 tests pass.
- Checked on a sample store with real input: Keep restored "Learn Rust" ("8 of 13" to "9 of 12") and ⌘Z took it back; Discard of "Quarterly report" restored it, ⌘Z took back the Restore ("7 of 14"), a second ⌘Z the Discard ("8 of 13"); Cancel restored nothing; ⌘⇧Z after an undo showed the Triage again. Start was disabled (Doing at its WIP Limit), as in any Triage. The refusal after a Triage couldn't be produced by hand (a Triage never takes room away); the Board test covers it.
- Review (medium) fixes: the redo goes through the gate (it skipped the Triage); the Restore's own reason line; a refusal with no window to show on falls back to an alert. Kept: a beep when the Board already has a sheet open (the Board comes forward showing it); the Triage step shared with the New Card sheet rather than a sheet of its own.
- Changed on 2026-11-08 at Christoph's request: "Doing is at its WIP Limit of 3. Finish a Card before / starting another." broke a word early. macOS's default line breaking pushes a word down to keep a single word off the last line; the texts in the Triage sheet (also the one before creating a Card, and the "No room" step) now break where the width ends. Checked by screenshot on a sample store: "… before starting / another.".
- Checked by hand by Christoph on 2026-11-08, as far as his real Board allows: with its current Cards a Restore needs no Triage, so he accepted the sample-store checks for the Triage outcomes and will report problems in use.
