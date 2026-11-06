# An Archived Card Event for archiving by hand; leaving after the Archive Delay stays computed

The user can now send a Done Card to the Archive before the Archive Delay is up, one Card at a time or all Done Cards at once. Each Card archived this way gets an **Archived** Card Event. A Done Card that leaves the Board because the Archive Delay is up still gets no event: that stays computed from its Moved-to-Done event, as in ADR 0002. A Done Card is in the Archive if it has an Archived event **or** its Done visit is older than the Archive Delay. Christoph decided this on 2026-11-06 because Done Cards stayed on the Board too long.

This amends ADR 0002, which rejected an Archived event. Its reasoning still holds for the automatic case, but archiving by hand is a decision the user makes at a moment, not a rule, so only an event can record it.

- **The Archive Delay is a setting** (1, 2, 3, 5 or 7 days, default 3). Because automatic archiving is computed, a change applies at once and retroactively: shortening it archives older Done Cards straight away, and lengthening it brings automatically archived Cards back to the Board. Cards archived by hand stay in the Archive. A change records no Board Event: unlike the WIP Limit, the Archive Delay changes no rule and no figure, only what the Board shows.
- **Archiving changes nothing the rules compute.** Throughput counts Moved-to-Done events from the last 14 days wherever the Card is (ADR 0001), so archiving early neither earns nor costs Capacity.
- **Undo deletes the Archived event**, like any other undo (ADR 0002): within 15 minutes, and "Archive All Done Cards" undoes as one step. It needs no confirmation for that reason.
- **Sample Cards can't be archived by hand.** Done Sample Cards offer no actions (ADR 0005), and an event of their own written now would sit among their backdated events.
- The event kind is a new value of the existing kind string, so the schema doesn't change (ADR 0002 forbids changes without a planned migration).

## Considered Options

- **Only a shorter fixed delay, no archiving by hand:** rejected. Any fixed value is either too long after a productive day or too short to enjoy what's finished.
- **Storing every archiving as an event, the automatic case included:** rejected for the reasons in ADR 0002. The app would have to backdate events it noticed late, and they would contradict the rule as soon as the Archive Delay changes, which is now a setting.
- **Moving a Card to the Archive as if it were a fourth Column (a Moved event to "archive"):** rejected. The Archive isn't a Column. Column Visits, Column Age and the allowed moves would all have to learn about it, and the Done visit would appear to end.

## Consequences

- The Board's archive check reads two sources: the Card's Archived event and the Archive Delay setting.
- Restoring a Card from the Archive is still not possible. It is a separate question (BACKLOG Inbox), because for a Discarded Card it touches Capacity.
- A dashboard can tell archiving by hand apart from automatic archiving, but it can't tell when an automatic archiving happened under an earlier Archive Delay.
