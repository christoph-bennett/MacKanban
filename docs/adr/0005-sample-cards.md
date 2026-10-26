# Sample Cards: marked by a UUID prefix, written into the past, removed without a trace

On first launch MacKanban offers to fill the Board with Sample Cards: everyday chores of every age, from fresh to fully red, so the Board shows how it works from the start. Christoph decided on 2026-10-26 that while they're on the Board they are ordinary Cards (they age, count toward Capacity, Throughput and the WIP Limit, go through Triage and record Card Events), so no rule needs to know about them. Three things set them apart, and each one is an exception to ADR 0002:

- **A Sample Card is recognised by a fixed prefix in its UUID.** Every Sample Card's ID starts with the same fixed bytes, and the rest is fixed per chore. Checking the prefix needs no schema change and no stored list. It also recognises Sample Cards written by an older app version after the set of chores changes.
- **Adding them writes events with past timestamps**, so the chores have their ages the moment they appear. The ages are relative to when they're added. Adding is only allowed while the Board has no Open Cards and no Sample Cards, so the mix's Capacity is known: at least 1 free slot, though a red Card means the next new Card goes through Triage.
- **Removing them deletes each Sample Card with all its Card Events** (Triaged events included) instead of Discarding them. They were never the user's work, so they shouldn't show up in a later Dashboard or in the Discard count. Board Events recorded while they were on the Board stay, because they're true facts about the Board at that moment. Removing can't be undone, but the Cards can be added again once the Board has no Open Cards.

Sample Cards can be moved and Discarded, but not edited, so their titles and notes stay the app's.

## Considered Options

- **A schema field ("isSample") on Card**: rejected. A code-defined model can't migrate automatically (ADR 0002), and a UUID prefix carries the same fact.
- **A list of sample IDs in UserDefaults**: rejected. It can drift from the store, doesn't travel with it (backup, a later iCloud sync), and adds state.
- **A title prefix such as "[Sample]"**: rejected. It's visible clutter, and it would sit in text that belongs to the user's view.
- **Sample Cards created now, all neutral**: rejected. They wouldn't show aging, which is what sets the app apart.
- **Removing them with a Discard**: rejected. The history would keep chores the user never had.

## Consequences

- The Board stamps every new event at least 1 ms after the latest one (ADR 0002). Backdated sample events sit before the user's own recent events. That's harmless, because Column Visits are replayed per Card and each Sample Card's own events have distinct timestamps.
- Removing Sample Cards also clears every undo entry that refers to one. Adding them can't be undone with ⌘Z. "Remove Sample Cards" is the way back.
- Whether the first-launch offer was shown is a UserDefaults flag (a display setting). It is offered only while the flag is unset and the Board has no Cards, so an existing Board never gets it.
