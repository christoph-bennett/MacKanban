# Core Data with a code-defined, CloudKit-ready model

The Board is stored with Core Data in a single SQLite store in `~/Library/Application Support/MacKanban/`. We chose it over a JSON file because Core Data leaves an open path to iCloud sync through `NSPersistentCloudKitContainer`. We chose it over SwiftData because SwiftData's macros need the compiler plugin server, which is fragile when building with SwiftPM and only the Command Line Tools (and blocked inside the Claude Code sandbox), and because Core Data is the more mature option on AppKit.

**The managed object model is built in code** (`NSManagedObjectModel`, `NSEntityDescription`), not in an `.xcdatamodeld` file, because `swift build` without Xcode doesn't compile model bundles (`momc`).

**The model follows CloudKit's constraints from the start, even though sync is not built:** every attribute is optional or has a default, there are no unique constraints, and every relationship is optional and has an inverse. Retrofitting these rules onto an existing store would take a migration, while following them now costs nothing.

A Card's history is stored as **Column Visits** (Column, entered, left). Card Age, Column Age, Throughput and the Archive all come from those records. Nothing derived from them, such as Urgency or Capacity, is ever stored.

## Consequences

- Turning on sync later needs a Developer ID signature, an iCloud container and entitlements. The current ad-hoc-signed build can't use CloudKit.
- With sync, two Macs could make conflicting moves to the same Card. Visits are append-only records, so the expected fix is to merge them in time order. This is not designed yet.
