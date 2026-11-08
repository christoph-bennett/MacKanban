# 02: Triage before a Restore

**What to build:** When Capacity would be nearly used up after a Restore, the Board comes forward with the Triage sheet, as with the New Card hotkey. After an outcome that still leaves room, the Card is restored at once, instead of the New Card sheet appearing; the gate is checked again after the Triage, since starting a Card can change its Urgency, and if there's no room any more the refusal from 01 shows. Dismissing the Triage restores nothing. This replaces 01's interim refusal. Spec 0005 stories 20–22; ADR 0008.

**Blocked by:** 01 (Restore from the Archive's context menu)

**Status:** ready-for-agent

- [ ] A Restore with one or fewer free slots left after it, or with a fully red Open Card on the Board, brings the Board forward with the Triage sheet for the most urgent Open Card
- [ ] Start, Discard or Keep in the Triage, then the Card is restored to Backlog; the Archive updates
- [ ] Dismissing the Triage restores nothing and records nothing beyond what Triage records today
- [ ] If the Triage leaves no room, the refusal shows instead of a Restore
- [ ] Undo after a Triage and Restore takes back the Restore first, then the Triage outcome as today
- [ ] 01's interim refusal is gone
- [ ] Board test for the gate checked after a Triage outcome
- [ ] Checked on a sample store with real input (one Triage per outcome, and a dismissal); Christoph checks by hand
