# Restore brings back Discarded Cards only, with their ages, and needs room for their whole cost

A Discarded Card can be brought back from the Archive (**Restore**), for example after Discarding it by mistake once Undo's 15 minutes are over. Christoph decided on 2026-11-08 how it fits the rules of ADR 0001, which say that no ordinary action may make old work look fresh:

- **Only Discarded Cards.** Done Cards can't be restored: nothing moves out of Done, and finishing, restoring and finishing again would count the same work toward Throughput twice. Work found unfinished after all becomes a new Card.
- **Ages unchanged.** Card Age keeps running through the time in the Archive, and Column Age adds up across Column Visits as always. A Card created three weeks ago comes back fully red. Resetting the ages would make Discard and Restore a way to make old work look fresh.
- **Always to Backlog**, whichever Column it was Discarded from, so the WIP Limit and a Doing Column Age that may be fully red don't stand in the way; the user starts it from there.
- **Room for its whole cost.** Restoring goes through the same gate as creating a Card, with one difference: a new Card is fresh and takes one free slot, a restored Card also brings its Urgency. Restore is blocked unless the Board still has no fewer than zero free slots after it, counted as Capacity counts (rounded down). Otherwise one Restore could put more on the Board than Capacity allows, the state the creation block exists to prevent. Triage applies as when creating, judged by the room left after the Restore.
- **A Restored Card Event**, a new value of the existing kind string, so the schema doesn't change (ADR 0002). The Discarded event stays in the history; the Restored event starts a new Backlog visit. Undo deletes it within 15 minutes, like any other undo.
- **A blocked Restore records nothing.** It isn't a creation, so it doesn't count as Creation Blocked.
- **Sample Cards can't be restored**, as they can't be archived by hand (ADR 0005, ADR 0007).

## Considered Options

- **Restoring Done Cards too ("reopen")**: rejected, see above.
- **Resetting the ages on Restore**: rejected, see above.
- **The same gate as creating (one free slot is enough)**: rejected. A fully red Card would push free slots below zero, past what the creation block allows.
- **A time limit on Restore**: rejected. With its ages and its cost, a restored Card can't be used to game the Board, however long it was in the Archive.

## Consequences

- The Board's Discarded check reads the Card's last Discarded event and whether a Restored event follows it.
- A Card can be Discarded, Restored and Discarded again; the Archive shows it once, with the date of its last Discard. A dashboard sees every event.
- The user sees a free slot on the Board and can still be refused a Restore. The refusal has to say why, with the numbers (spec 0005).
