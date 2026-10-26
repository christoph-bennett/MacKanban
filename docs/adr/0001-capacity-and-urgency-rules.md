# Capacity and Urgency rules are fixed and can't be gamed

The Board exists to stop the Backlog from turning into a dumping ground, so its rules are built so that no ordinary action makes old work look fresh, and so that the user can't loosen them.

- **Urgency** runs from 0 (neutral) to 1 (full red) and stays at 0 during a grace period, then rises linearly. Backlog Cards use Card Age (neutral up to 12 hours, full red at 21 days). Doing Cards use Column Age (neutral up to 4 hours, full red at 7 days). The grace periods were 3 days and 1 day until ADR 0004 shortened them. Done Cards have none.
- **Column Age adds up across Column Visits.** Moving a Card from Doing back to Backlog and then into Doing again does not restart its Doing clock. Editing a Card, keeping it during Triage, and undoing a move also leave both ages unchanged. Undo deletes the reverted event (ADR 0002), so the Card's history reads as if the slip never happened.
- **Capacity = 5 + Throughput − Σ Urgency of all Open Cards**, rounded down and capped at 20, with **no floor**. Throughput is the number of Cards moved to Done in the last 14 days. Capacity is recomputed continuously, so it can fall while the app sits unused.
- **Discard is allowed but earns nothing.** A Discarded Card leaves the Board and stops costing Capacity, but it doesn't count as Throughput.
- **The thresholds, the formula and the 14-day window are not settings.** The only setting that touches the rules is the WIP Limit (1–5). Display settings such as hiding the age labels are fine: they change nothing the rules compute.

## Considered Options

- **Configurable thresholds**: rejected. Setting "full red at 365 days" would switch off the whole mechanism.
- **A Capacity floor** (e.g. never below the WIP Limit): rejected. Hitting zero is the intended signal, and it can't deadlock, because finishing or Discarding a Card is always possible.
- **Resetting Column Age on every move**: rejected. Bouncing a Card between Columns would wipe its age.
- **Free deletion**: rejected in favour of Discard. Deleting old Cards would reset the Board's pressure at no cost.
- **Guarding Throughput against farming** (only counting Cards with a minimum Card Age or a minimum time in Doing): rejected. Creating a trivial Card and finishing it right away raises Capacity by one, but that only fools the user, and the cap of 20 limits it. Every Card must still pass through Doing on its way to Done, so a Card can't go from Backlog straight to Done.

## Consequences

The user can open the app after a weekend away and be unable to create anything. That is intended, so the Capacity gauge must always explain where Capacity went (for example "−2.4 from aging Cards").
