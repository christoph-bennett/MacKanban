# 12: Sample Cards

**What to build:** Sample Cards (GLOSSARY, ADR 0005), from the grilling on 2026-10-26.

- **Board:** an operation that adds the Sample Cards and one that removes them, plus a query for whether any exist. A Sample Card's ID starts with a fixed UUID prefix; each chore has a fixed ID. Adding writes Created, Moved and Discarded events with past timestamps relative to now, and is refused unless the Board has no Open Cards and no Sample Cards. Removing deletes every Sample Card (Archive included) with all its events and leaves Board Events alone. `edit` refuses a Sample Card. Moving and Discarding work as usual.
- **The mix:** about 12–14 everyday chores (nothing techy, no kids, no doctors; puppies and dogs are fine) covering every stage of aging, like `SampleBoard`. Backlog about 5 (fresh to fully red), Doing 2–3 (fresh to amber, within the default WIP Limit of 3), Done and Archive about 6, including one Discarded and one finished more than 7 days ago. Enough recent Done Cards that the Board right after adding has at least 1 free slot (a red Card means the next new Card goes through Triage, which is intended).
- **First launch:** an `NSAlert` over the Board window, once: "Try MacKanban with sample Cards?" / "A few everyday chores of different ages show how Cards age and how the Board limits new work. You can remove them anytime from the menu bar menu; your own Cards stay." Buttons **Add Sample Cards** (default) and **Start Empty**. Shown only while a UserDefaults flag is unset and the Board has no Cards; set the flag on that launch whatever the answer.
- **Menu bar extra:** one entry, and nothing in the main menu. "Add Sample Cards" while the Board has no Open Cards and no Sample Cards; "Remove Sample Cards" while any Sample Card exists. Remove asks first ("Remove N sample Cards? Your own Cards stay.").
- **Cards:** a Sample Card has no edit pencil, double-clicking it does nothing, and its age line starts with "Sample" ("Sample · 5d old"); the label stays when "Show ages on Cards" is off.
- **Undo:** adding can't be undone; removing clears undo entries that refer to Sample Cards; moving and Discarding a Sample Card undo as usual.

**Blocked by:** none

**Status:** to do

- [ ] Adding is refused with an Open Card or a Sample Card on the Board, and works otherwise (including with the user's own Done or Archived Cards)
- [ ] Right after adding: every stage from neutral to fully red is on the Board, Doing is within the WIP Limit, at least 1 slot is free, and the Archive has a Discarded and a finished Sample Card
- [ ] Removing deletes every Sample Card and its events, keeps the user's Cards (also ones created after the samples) and all Board Events
- [ ] Editing a Sample Card is refused; moving and Discarding it work and record events
- [ ] The first-launch alert appears once, only with the flag unset and an empty Board
- [ ] The menu bar entry switches between Add and Remove as above, and Remove asks first
- [ ] Sample Cards show "Sample" in the age line and have no pencil
- [ ] ⌘Z never refers to a removed Sample Card
