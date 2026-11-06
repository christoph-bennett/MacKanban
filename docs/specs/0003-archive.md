# Spec 0003 — Archive: archiving by hand, Archive Delay setting, a clearer Archive window

Status: ready-for-agent

Vocabulary follows [GLOSSARY.md](../../GLOSSARY.md) (Archive, Archive Delay, Card Event). Respects [ADR 0007](../adr/0007-archived-event-for-manual-archiving.md), which amends [ADR 0002](../adr/0002-core-data-event-log.md), and leaves [ADR 0001](../adr/0001-capacity-and-urgency-rules.md) untouched. Designed with Christoph on 2026-11-06. It changes spec 0001's stories 15–16 and its Defaults line ("7-day Archive delay … constants").

## Problem Statement

Done Cards stay on the Board for 7 days. After a productive stretch, Done fills up with Cards I've long stopped caring about, and the Board looks busier than my work is. I can't clear it: Done Cards can't be moved, and the delay is fixed. When I open the Archive, Done and Discarded Cards are mixed in one list, told apart only by an Outcome column, which is confusing. And I can't see which archived Cards still count toward Throughput, so it's unclear why my Capacity is what it is, or when it will drop.

## Solution

I can send a Done Card to the Archive whenever I like, from its context menu or with ⌘⌫, or clear all of Done at once. Both can be undone with ⌘Z. How long Done Cards stay on the Board on their own, the Archive Delay, is now my choice in Settings > General (1, 2, 3, 5 or 7 days, 3 by default). The Archive window shows two sections, Done and Discarded, each newest first. In the Done section a "Counts" column shows how much longer each Card counts toward Throughput: a small bar that drains over the 14 days and a date ("until Nov 10"). Cards that no longer count are greyed out. None of this changes Capacity: a Done Card counts for 14 days after it was finished, wherever it is.

## User Stories

Archiving by hand

1. As a user, I want to archive a Done Card from its context menu ("Archive"), so that Done only shows what I still want to see.
2. As a user, I want "Archive" in a Done Card's context menu where Open Cards have "Discard", after a separator, so that removing a Card from the Board is always in the same place.
3. As a user, I want the Card menu's ⌘⌫ item to read "Archive Card" while a Done Card is selected and "Discard Card" while an Open Card is selected, so that the same key takes the selected Card off the Board, whatever its Column.
4. As a user, I want "Archive All Done Cards" in the Card menu and in every Done Card's context menu, so that I can clear Done in one go after a productive stretch.
5. As a user, I want "Archive All Done Cards" to be disabled when Done is empty or holds only Sample Cards, so that the menu never offers something that does nothing.
6. As a user, I want archiving to happen without a confirmation, so that clearing Done is quick, since I can undo it.
7. As a user, I want an archived Card to leave the Board straight away and appear at once in an open Archive window, so that I see the result.
8. As a user, I want the selection to move sensibly after archiving (as after a Discard), so that I can keep working with the keyboard.
9. As a user, I want ⌘Z to undo archiving a Card within 15 minutes, putting it back in Done where it was, so that a slip costs nothing.
10. As a user, I want ⌘Z to undo "Archive All Done Cards" as one step, bringing back every Card it archived, so that one slip needs one undo.
11. As a user, I want Redo to archive the Card(s) again, so that undo and redo behave as everywhere else in MacKanban.
12. As a user, I want an undo after 15 minutes to be refused with the usual message, so that undo stays for slips, not for rewriting history (ADR 0002).
13. As a user, I want archiving a Card to leave its Throughput unchanged, so that clearing Done neither earns nor costs Capacity.
14. As a user, I want Done Sample Cards not to offer "Archive" (they offer nothing, as today) and "Archive All Done Cards" to skip them, so that Sample Cards keep behaving as described (ADR 0005).
15. As a user, I want a Card I archived by hand to stay in the Archive whatever I set the Archive Delay to later, so that my decision sticks.
16. As a user, I want the Card menu's archive items disabled while a sheet is open, as the other Card items are, so that ⌘⌫ typed in a sheet never archives a Card.
17. As a user, I want archiving by hand recorded in the Card's history (an Archived Card Event), so that a later Dashboard can tell it apart from leaving after the Archive Delay.

Archive Delay setting

18. As a user, I want to choose the Archive Delay under Settings > General from a dropdown like the WIP Limit's, with 1, 2, 3, 5 and 7 days, so that Done keeps Cards as long as suits me.
19. As a user, I want the Archive Delay to be 3 days unless I change it, including on the first launch after this update, so that Done is shorter than before without my doing anything.
20. As a user, I want a short note under the dropdown explaining it ("How long Done Cards stay on the Board before they go to the Archive. Archiving early doesn't change Throughput."), so that I know it doesn't touch Capacity.
21. As a user, I want a change to the Archive Delay to apply at once and to every Done Card: shortening it archives older Done Cards right away, lengthening it brings back Done Cards that had left only because of the delay, so that the Board always matches the setting.
22. As a user, I want a Done Card to leave the Board within a minute of its Done visit reaching the Archive Delay, as it does today with 7 days, so that the setting is honoured while the app runs.
23. As a user, I want the Archive Delay to survive relaunching MacKanban, so that I set it once.
24. As a user, I want a MacKanban opened on a sample store to keep its own Archive Delay, as it keeps its own WIP Limit, so that screenshots don't change my real setting.
25. As a user, I want a change to the Archive Delay not to be recorded as a Board Event, so that the history holds only what matters to the rules (ADR 0007).

Archive window

26. As a user, I want the Archive window to show a section for Done Cards and one for Discarded Cards, Done first, each with a heading, so that the two kinds aren't mixed.
27. As a user, I want each section sorted newest first, so that what I finished or dropped last is on top.
28. As a user, I want the Done section to show and sort by the date a Card was finished, also for Cards I archived by hand, so that the date means the same for every row.
29. As a user, I want the Outcome column gone, since the sections say it, so that the table is simpler.
30. As a user, I want the columns Card, Created, Ended (finished or Discarded, as the section heading says) and Counts, with Counts empty for Discarded Cards, so that one header row serves both sections.
31. As a user, I want a section with no Cards hidden, and "Nothing in the Archive yet." when both are empty, so that the window never shows empty headings.
32. As a user, I want the Counts column to show a small bar that drains from full on the day a Card was finished to empty 14 days later, so that I see at a glance how much longer each Card props up my Capacity.
33. As a user, I want the Counts column to also say "until Nov 10" (the day its 14 days end, in my locale's short date format), so that I know exactly when Capacity will drop by one.
34. As a user, I want a Card whose 14 days are over to show "no longer" and its whole row greyed out (secondary text colour), so that I see where counting ends.
35. As a user, I want the Archive to keep updating once a minute while it's open, so that bars, dates and greying stay current.
36. As a user, I want to keep navigating the Archive with ↑↓, opening a Card with Return or a double-click, and closing with Esc, across both sections, so that nothing I've learned changes; section headings can't be selected.
37. As a user, I want the selected Card to stay selected across reloads, as today, so that a reload doesn't throw me off.
38. As a user, I want archived Cards to open read-only as today ("Done Card" or "Discarded Card"), so that the Archive stays a place to look back.
39. As a user, I want the Archive's sections, bars and greying to be readable with VoiceOver (the section names announced, the Counts cell read as "Counts toward Throughput until Nov 10" or "No longer counts toward Throughput"), so that the window stays accessible.
40. As a user, I want the bar to use colours that work in light and dark mode and in high contrast, so that it's readable everywhere.

Unchanged

41. As a user, I want Capacity, Throughput and the Capacity gauge's breakdown to behave exactly as before, so that the rules stay fixed (ADR 0001).
42. As a user, I want Done's count beside its title to keep counting only the Cards on the Board, so that it shrinks when I archive.
43. As a user, I want Discarded Cards to go to the Archive straight away, as today, so that only Done is affected by the new controls.

## Implementation Decisions

- **Event kind:** a new Card Event kind, Archived, stored as a new value of the existing kind string. No schema change (ADR 0002, ADR 0007). The public Event kind enum gains the case, and the event log query returns it.
- **Archive rule (one place):** a Done Card is in the Archive if it has an Archived event, or its Done visit is at least the Archive Delay old. Both the Board state and the Archive query use this one rule, as `isArchived` does today. An Archived event isn't a change of Column: Column Visits, Column Age, Card Age and Throughput ignore it.
- **Board: Archive Delay.** The Board is created with the stored Archive Delay, like the WIP Limit; one outside the allowed set becomes the default. The Board exposes the allowed values (1, 2, 3, 5, 7 days), the default (3 days) and a way to change it, which writes no event. The fixed 7-day constant goes away.
- **Board: archive operations.** "Archive a Card" takes a Done Card's ID, records one Archived event and returns a Change for undo; it refuses an Open Card, a Card already in the Archive, and a Sample Card (typed errors the app turns into messages). "Archive all Done Cards" archives every Done Card on the Board except Sample Cards, all with one Change, so that one undo reverts them together (the Change's companions mechanism carries the other events). It refuses when there's nothing to archive.
- **Undo:** reverting an archive deletes its Archived event(s), within the 15-minute undo window. The existing undo check, "the event is the Card's latest change of Column", is extended so that an Archived event counts as a placing event for this purpose: once a Card is archived, an older move can't be undone underneath it, and the archive itself can be undone. Redo runs the operation again at the current time, as for every other change.
- **Archive query:** returns the Archive already split: Done entries and Discarded entries, each newest first. A Done entry carries its Card, Created date, Done date and the end of its Throughput window (Done date + 14 days, the Capacity window constant, not a copy). Discarded entries carry Card, Created and Discarded date. The Outcome distinction becomes the split; the window doesn't sort or filter.
- **Throughput window end** comes from the same constant Capacity uses, so the Counts column can't drift from the rule.
- **Settings > General:** a new row "Archive Delay:" with a dropdown (the same pop-up button kind as the WIP Limit), items "1 day", "2 days", "3 days", "5 days", "7 days", and the note from story 20. Stored in the app's defaults (the sample store's separate defaults apply, as for the WIP Limit). A change goes through the Board and refreshes the Board window and an open Archive window.
- **Board window menus:** the Done Card context menu gains "Archive" and "Archive All Done Cards" after a separator (Sample Cards still get no menu). The Card menu's ⌘⌫ item switches its title and action by the selected Card's Column ("Discard Card" or "Archive Card"), following the existing pattern that switches "Edit Card…" and "Open Card". A new item "Archive All Done Cards" follows it, without a shortcut. All are disabled while a sheet is open.
- **Archive window:** stays an AppKit table. Section headings are group rows ("Done", "Discarded"), not selectable, skipped by arrow keys. The Done section's Counts cell holds a small level-indicator-style bar (14 days at full, draining linearly) and the text "until <short date>"; an expired row shows "no longer" and uses the secondary label colour for all its cells. Column headers: Card, Created, Done/Discarded, Counts. Since one table has one header row, the third column is headed "Ended" and the section heading says which date it is; the Counts column is empty for Discarded rows. The minute timer, reload on Board changes, kept selection, empty message and Esc stay.
- **Menu bar extra:** unchanged.
- **Sample stores:** `SampleBoard` keeps working; with the new default, its Done Cards older than 3 days now show in the Archive, which gives screenshots both counting and expired rows.

## Testing Decisions

- **One seam: Board**, as in spec 0001. Tests build the Board over an in-memory store with the injected clock and assert only on what its queries return. No new seam; the AppKit parts are checked by screenshot and by hand.
- A good test describes a scenario a user could live through ("finish a Card, archive it, it's in the Archive and still counts 13 days later") and doesn't look at events' storage or private helpers, so the rule can be refactored freely.
- Board scenarios to add (extending the existing archive and undo tests):
  - archiving a Done Card removes it from Done and puts it first in the Archive's Done entries; Throughput and Capacity are unchanged
  - archiving an Open Card, an archived Card or a Sample Card is refused with its error
  - Archive All archives every non-Sample Done Card and leaves Sample Cards; with nothing to archive it's refused
  - undo of one archive and of Archive All (one step) brings the Cards back to Done; refused after 15 minutes; an older move can't be undone after the Card was archived
  - the Archive Delay: default 3 days; a Done Card visible just before, archived at the delay; changing the delay archives and un-archives automatically archived Cards at once; a hand-archived Card stays archived after lengthening; an out-of-range stored value becomes the default; a change writes no event
  - the Archive query: Done and Discarded entries split and each newest first; the Throughput window end is Done + 14 days; a hand-archived Card is sorted by its Done date
  - the event log returns Archived events
- Existing tests that pin the 7-day constant are rewritten against the configurable delay; all other tests stay green.
- Prior art: the existing archive tests (a Done Card visible at 6 days, archived at 7), the undo tests (window, refusals) and the WIP Limit tests (setting with an allowed range and a default).
- Checked by screenshot on a sample store: the Archive window with both sections, counting and expired rows; Settings > General with the new row; a Done Card's context menu. Then Christoph checks by hand (⌘⌫ on a Done Card, Archive All with undo, changing the delay).

## Out of Scope

- Restoring a Card from the Archive to the Board (BACKLOG Inbox, 2026-11-06).
- The Dashboard (BACKLOG Later; its own grill).
- A Counts marker on Done Cards on the Board (they all count while the Archive Delay is at most 7 days).
- An Archive Delay of more than 7 days or "never".
- A button in Done's column header.
- Deleting Cards from the Archive.

## Further Notes

- Spec 0001's stories 15 and 16 and its Defaults line are superseded by this spec (add a dated note there when implementing).
- After the update, the default of 3 days will take his Done Cards older than 3 days off the Board straight away. That's intended.
