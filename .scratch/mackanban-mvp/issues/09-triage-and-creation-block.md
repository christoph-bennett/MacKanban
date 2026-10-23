# 09: Triage and the creation block

**What to build:** The creation gate on the New Card sheet. **Open** (3 or more free slots and no fully red Open Card): the sheet goes straight to title and notes. **Triage** (2 or fewer free slots, or any Open Card at Urgency 1): the sheet first shows the Open Card with the highest Urgency and offers **Start** (move to Doing, unavailable with a reason when Doing is at the WIP Limit), **Discard** and **Keep**. Any of these then continues to title and notes. Closing the sheet counts as **dismissed**. Every Triage appends a Triaged event on the triaged Card with its outcome, alongside the usual Moved or Discarded event. **Blocked** (0 or fewer free slots): the sheet explains ("Capacity 7, Open Cards 9: finish or Discard 3 Cards") and offers no way to create. Each blocked attempt appends a Creation Blocked Board Event with the Capacity and Open Card count. Undoing a Triage start or Discard also removes its Triaged event.

**Blocked by:** 04, 08

**Status:** ready-for-agent

- [ ] The gate is open, Triage or blocked exactly as described, and Triage shows the Card with the highest Urgency
- [ ] Start, Discard and Keep work, Start is unavailable with a reason at the WIP Limit, and Keep changes no Urgency
- [ ] Every Triage records one Triaged event with outcome started, discarded, kept or dismissed
- [ ] Blocked shows the explanation, can't create, and records one Creation Blocked event per attempt
- [ ] The Board refuses create when blocked, even if called directly
- [ ] Board tests: gate states and thresholds, Triage choosing the highest Urgency, Triaged and Creation Blocked events, create refused when blocked
