# 02: Create Cards and see them in Backlog

**What to build:** The store and the Board facade, with creating a Card end to end. The Core Data model is built in code and follows CloudKit's constraints (ADR 0002): a `Card` entity (UUID set at creation, title, notes) and an `Event` entity (kind, timestamp, optional card, optional kind-specific fields). History lives only in the event log. The Board facade takes an injected clock and container (SQLite in Application Support in the app, in-memory in tests). Creating a Card appends a Created event. ⌘N (and a New Card button above the Columns) opens a sheet for title and optional notes. No Capacity gate yet. New Cards appear in Backlog, oldest first, and survive a relaunch.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The model is defined in code with no `.xcdatamodeld`. All attributes are optional or have defaults, there are no unique constraints, and relationships are optional with inverses
- [ ] Creating a Card stores a UUID, title and notes, and appends exactly one Created event with the clock's time
- [ ] An empty title can't be saved
- [ ] Backlog lists Cards oldest first, and the Card's Column is computed from its events, not stored
- [ ] Cards are still there after quitting and relaunching
- [ ] The Board exposes the event log in time order
- [ ] Board tests (in-memory store, injected clock): create, Backlog order, Created event recorded, data surviving a container reload against a temporary SQLite file
