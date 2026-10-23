# Core Data storing an append-only event log, with a code-defined, CloudKit-ready model

The Board is stored with Core Data in a single SQLite store in `~/Library/Application Support/MacKanban/`. We chose it over a JSON file because Core Data leaves an open path to iCloud sync through `NSPersistentCloudKitContainer`. We chose it over SwiftData because SwiftData's macros need the compiler plugin server, which is fragile when building with SwiftPM and only the Command Line Tools (and blocked inside the Claude Code sandbox), and because Core Data is the more mature option on AppKit.

**History is an append-only event log, and it is the only record of what happened.** A Card stores only its UUID, title and notes. Everything else is an **Event** with a kind, a timestamp and an optional Card:

- **Card Events:** Created, Moved (from Column, to Column), Edited (only that it happened), Discarded, and Triaged (outcome: started, discarded, kept or dismissed).
- **Board Events:** Creation Blocked (Capacity and Open Card count at that moment) and WIP Limit Changed (from, to).

The current Column, Column Visits, Card Age, Column Age, Throughput and the Archive are all computed from the events. Nothing derived from them is stored, including Urgency, Capacity and "archived". We record the Board's history from day one so that a later dashboard has data, even though the MVP only reads what its rules need. The overhead is a few dozen bytes per event, and events are never pruned.

- **Undo deletes the event it reverts** instead of appending a compensating one. Undo is for slips straight after they happen, and slips aren't history: it works only within 15 minutes, only while the event is still the Card's latest change of Column (Edited events don't count), and never when it would put Doing over the WIP Limit. Redo runs the operation again at the current time. Board Events can't be undone.
- **A Card's ID is a UUID attribute**, set at creation and never changed. `NSManagedObjectID` isn't usable here: it's temporary until the first save, and it differs per device under CloudKit.
- **The model is built in code** (`NSManagedObjectModel`, `NSEntityDescription`), not in an `.xcdatamodeld` file, because `swift build` without Xcode doesn't compile model bundles (`momc`).
- **The model follows CloudKit's constraints from the start, even though sync is not built:** every attribute is optional or has a default, there are no unique constraints, and every relationship is optional and has an inverse. Retrofitting these rules onto an existing store would take a migration.

## Considered Options

- **Column Visits as stored state** (Column, entered, left), plus a separate event log: rejected. The same fact would be stored twice, and the two copies could disagree.
- **Separate entities for Card Events and Board Events:** rejected in favour of one Event entity. A dashboard reads one table in time order, and there's a single CloudKit record type. Most kinds leave some optional fields empty.
- **An Archived event:** rejected. Archiving follows from a rule (7 days after entering Done), so the app would have to backdate an event it noticed late, and the stored events would contradict the rule if the delay ever changed.

## Consequences

- Turning on sync later needs a Developer ID signature, an iCloud container and entitlements. The current ad-hoc-signed build can't use CloudKit.
- Append-only events merge well under sync. Two Macs moving the same Card at once can still produce an impossible sequence, such as two Moved events out of Backlog. The rule for resolving that is not designed yet.
- Automatic (lightweight) migration finds the store's old model by searching compiled model bundles, and a code-defined model has none. Every schema change after a store exists therefore needs the previous model version kept in code. To avoid that during the MVP, the Event entity defines every field the spec names up front, before any ticket writes them (found in ticket 02).
- The log's order comes only from timestamps, because a sequence number would be a schema change. The Board therefore stamps each new event at least 1 ms after the latest one, so no two events share a time even when the clock hasn't moved (in tests, or after a clock change). Replaying a Card's Column Visits relies on this (found in ticket 03).
- Every query that computes state has to replay a Card's events in time order. At this app's size that's trivial, but it's the reason not to put heavy logic in views.
