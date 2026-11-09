# Kanban Board

A single-person, local to-do board that pushes back against an ever-growing backlog: cards visibly age, and the board limits how much new work can be added while old work goes untouched.

## Language

### Board structure

**Board**:
The single board the user works on. It has exactly three fixed Columns, and the user cannot add, remove or rename them.
_Avoid_: Project, list

**Column**:
One of the three fixed stages a Card can be in: Backlog, Doing or Done.
_Avoid_: Lane, swimlane, stage, status

**Backlog**:
The Column for Cards that have been captured but not started.
_Avoid_: To do, inbox

**Doing**:
The Column for Cards currently being worked on. A WIP Limit applies to it.
_Avoid_: In progress, active

**Done**:
The Column for finished Cards. Nothing moves out of Done.
_Avoid_: Complete, finished

### Cards

**Card**:
One piece of work on the Board, made up of a title and optional notes.
_Avoid_: Item, todo, task, ticket

**Column Visit**:
One stretch of time a Card spent in a Column, from when it entered to when it left. It follows from the Card's Card Events.
_Avoid_: Transition, move, history entry

**Card Event**:
A recorded fact about one Card at a point in time: Created, Moved (from one Column to another), Edited, Discarded, Restored, Triaged (with its outcome) or Archived (the user sent a Done Card to the Archive before the Archive Delay was up). A Card's Card Events are its complete history. Edited records only that an edit happened, not what changed. A Done Card leaving the Board once the Archive Delay is up is not a Card Event, because it follows from a rule rather than happening.
_Avoid_: Activity, log entry, change, transition

**Board Event**:
A recorded fact about the Board rather than one Card: Creation Blocked (with the Capacity and Open Card count at that moment) or WIP Limit Changed.
_Avoid_: System event, audit entry

**Open Card**:
A Card in Backlog or Doing.
_Avoid_: Active card, pending card

**Discard**:
Removing an Open Card from the Board on purpose because the work won't be done. It is recorded, but it isn't a completion.
_Avoid_: Delete, cancel, abandon

**Restore**:
Bringing a Discarded Card back from the Archive, for example after Discarding it by mistake. The Card becomes an Open Card again with its ages unchanged, and it needs room in Capacity like a new Card. Done Cards can't be restored.
_Avoid_: Undiscard, reopen, unarchive

**Sample Card**:
A Card the app adds to show how the Board works, rather than one the user created. While on the Board it ages, counts and records Card Events like any other Card, and it can be moved or Discarded, but not edited. Removing Sample Cards takes them and their whole history off the Board, leaving no trace.
_Avoid_: Demo card, example card, placeholder

**Archive**:
Where Cards go when they leave the Board for good: Done Cards once the Archive Delay is up or when the user archives them earlier, and Discarded Cards straight away. A Done Card in the Archive still counts toward Throughput for as long as it would on the Board.
_Avoid_: Trash, history

**Archive Delay**:
How long a Done Card stays on the Board before it goes to the Archive on its own. The user chooses it.
_Avoid_: Retention, archive period

### Age and urgency

**Card Age**:
Time since a Card was created. It never resets.
_Avoid_: Created age, lifetime

**Column Age**:
Total time a Card has spent in its current Column, added up across every visit. Moving the Card away and back again does not reset it.
_Avoid_: Time in column, stage age, dwell time

**Urgency**:
How strongly a Card signals that it needs attention. In Backlog it comes from Card Age, in Doing from Column Age, and Done Cards have none.
_Avoid_: Staleness, heat, rot

### Limits

**WIP Limit**:
The maximum number of Cards allowed in Doing at once. The user sets it, and it is enforced strictly.
_Avoid_: Doing limit, max active

**Throughput**:
The number of Cards moved to Done in the last 14 days. Discarded Cards don't count.
_Avoid_: Velocity, completion rate

**Capacity**:
The maximum number of Open Cards the Board allows right now. It rises with Throughput and falls as Open Cards age.
_Avoid_: Creation limit, backlog limit, quota

**Triage**:
The step forced on the user before creating a Card when Capacity is nearly used up. They are shown the Open Card with the highest Urgency and must start it, Discard it or explicitly keep it, or dismiss the sheet without creating anything. Keeping a Card does not change its Urgency.
_Avoid_: Review, check-in

### Looking back

**Dashboard**:
The read-only look back at the Board's history, answering whether the user finishes what they start and where Cards get stuck. It states facts only: it offers no actions, goals, scores or advice.
_Avoid_: Statistics, insights, report
