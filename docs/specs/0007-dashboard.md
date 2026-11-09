# Spec 0007 — Dashboard: a look back at the Board's history

Status: parked until 2026-12-01

Vocabulary follows [GLOSSARY.md](../../GLOSSARY.md) (Dashboard, Board Event, Card Event, Throughput, Triage, Card Age, Column Age, Sample Card). It only reads the event log of [ADR 0002](../adr/0002-core-data-event-log.md), needs no schema change, and leaves the rules of [ADR 0001](../adr/0001-capacity-and-urgency-rules.md) untouched. It follows [ADR 0005](../adr/0005-sample-cards.md) (Sample Cards) and [ADR 0008](../adr/0008-restore-discarded-cards.md) (a Dashboard sees every event). Designed with Christoph on 2026-11-09 (grill about the BACKLOG Later item).

**Parked on purpose.** On 2026-11-09 the real store held two weeks of events, too little to show change over time. No data is lost by waiting, since the events are recorded anyway. From 2026-12-01, four weeks after real use began, go through this spec against the real data and Christoph's own questions by then, change it where needed, set its status to ready-for-agent, and only then write the tickets.

## Problem Statement

My Board shows me where things stand right now, and that's all it shows. I can't see whether I finish what I start, or where Cards get stuck. I can't tell whether the Board is growing or shrinking, which Cards I keep putting off in Triage, how often creating was blocked, or whether my changes to the WIP Limit fit what happened afterwards. The app has recorded all of this from the start, but none of it is visible.

## Solution

A Dashboard window, opened like the Archive, looks back over 4 Weeks, 12 Weeks or All. Its main picture is a Sankey diagram showing where the Cards of that time went: from already open or newly created, through Backlog and Doing, to Done, Discarded, still in Doing or still in Backlog. Below it are the counts per week, then the Cards kept repeatedly in Triage, how often creating was blocked, and the WIP Limit changes. Backlog and Doing say how long Cards stay there and how old the oldest one still there is. The window only states facts. It offers no actions, goals, scores or advice.

## User Stories

Opening it

1. As a user, I want a Dashboard item in the Window menu, beside Archive, so that I find it where I find my other windows.
2. As a user, I want "Open Dashboard" in the menu bar extra's menu, beside "Open Archive", so that I reach it while the Dock icon and the app's menu bar are hidden.
3. As a user, I want ⌘⇧D to open it, like ⌘⇧A for the Archive, so that I get there by keyboard.
4. As a user, I want no global hotkey for it, since looking back doesn't need to happen from any app.
5. As a user, I want its own window that I can resize, and that remembers its size, so that it fits beside my Board.

What it is

6. As a user, I want it to answer whether I finish what I start and where Cards get stuck, so that a look at it can lead me to change my WIP Limit or Discard more.
7. As a user, I want only facts, with no goals, scores, streaks, warnings or advice, so that it doesn't become a game or nag me.
8. As a user, I want no actions and no settings in it apart from the time span, so that changes happen on the Board or in Settings as before.
9. As a user, I want nothing in it to change my Capacity, Urgency or any other rule, so that looking back has no effect on the Board (ADR 0001).

The time span

10. As a user, I want to choose 4 Weeks, 12 Weeks or All, so that I can look at recent work or at everything.
11. As a user, I want 12 Weeks as the default, so that it opens on a useful look back.
12. As a user, I want my last choice remembered, per store, so that it opens the way I left it.
13. As a user, I want weeks to run from Monday to Sunday, and a span to be the current week plus the weeks before it, so that the numbers are in whole weeks.
14. As a user, I want All to begin at the store's first event, so that nothing is left out.
15. As a user, I want the time span to apply to everything except what says "still" and "oldest", which show today, so that I can tell looking back from where things stand.

Where Cards went

16. As a user, I want a Sankey diagram as the main picture, so that I see at a glance where my Cards landed.
17. As a user, I want each Card counted exactly once, so that the left side always adds up to the right side.
18. As a user, I want the left side to show "Already open" and "Created", so that I see what I started the time span with and what I added.
19. As a user, I want the right side to show Done, Discarded, Still in Doing and Still in Backlog, so that I see how it all ended.
20. As a user, I want every Card that was in Doing during the time span to run through Doing, so that I see what I really started.
21. As a user, I want a Card that was already in Doing when the time span began to run straight from "Already open" to Doing, past Backlog, so that the picture doesn't claim something false.
22. As a user, I want a Card that went from Doing back to Backlog drawn without a loop, through Doing and ending in Still in Backlog, so that the picture stays readable and the sums still work.
23. As a user, I want a Card that was Discarded and then Restored counted by where it ended, so that a mistake I fixed doesn't show as a Discard here.
24. As a user, I want Cards that were already Done or Discarded when the time span began left out, so that the picture is about that time.
25. As a user, I want the number of Cards beside each part of the picture, and exact numbers when I hover a band, so that I don't have to judge widths.
26. As a VoiceOver user, I want the same numbers as a table, and a spoken summary of the picture, so that it doesn't depend on seeing it.

Per week

27. As a user, I want Created, Moved to Done and Discarded per week, so that I see the course over time, which the Sankey can't show.
28. As a user, I want the weekly number called "Moved to Done", and Throughput kept for the 14-day number that counts toward Capacity, so that one word keeps one meaning.
29. As a user, I want the current week marked as not over yet, so that a low number on a Monday doesn't mislead me.
30. As a user, I want the weekly bars to show what happened: a Discard counts in its week even if the Card was Restored later, so that they stay a record of events.
31. As a user, I want a short note saying the weekly bars and the Sankey can differ for that reason, so that the difference doesn't look like a bug.
32. As a user, I want a Restore to add no bar and not to count as Created, so that a Card returning doesn't look like new work.
33. As a user, I want the exact numbers when I hover a week, so that small bars can still be read.

How long Cards stay

34. As a user, I want the median time for Backlog and for Doing shown at those two parts of the Sankey, so that I see where Cards spend their time.
35. As a user, I want the median to cover every Card that left the Column during the time span, Discards included, so that it isn't only about what went well.
36. As a user, I want the oldest Card still in each Column, with its title and age, so that a Card stuck for 40 days isn't hidden behind a median of 2 days.
37. As a user, I want times measured as on the Board, Card Age in Backlog and Column Age in Doing added up across visits, so that the Dashboard and the Board agree.
38. As a user, I want "–" for a median when no Card left the Column, and no oldest Card when none is there, so that nothing made up is shown.

Kept in Triage

39. As a user, I want a list of Cards kept at least twice in Triage during the time span, with title, count and current Column, sorted by count, so that I see what I keep putting off.
40. As a user, I want Cards in the list even if they're Done or Discarded by now, so that I still see that they were put off.
41. As a user, I don't want a dismissed Triage to count, since no decision about the Card was made.
42. As a user, I want a plain line when no Card was kept twice, so that an empty space doesn't look like a fault.

Also in this time

43. As a user, I want how often creating was blocked during the time span, as one number, so that I see whether my Capacity holds what I start.
44. As a user, I want the WIP Limit changes during the time span as a list with date, from and to, so that I can read the other numbers against them.
45. As a user, I want a refused Restore not counted as blocked, as spec 0005 decided, so that two different things stay apart.

Sample Cards and Undo

46. As a user, I want Sample Cards' Card Events never counted, so that invented, backdated history doesn't look like my work (ADR 0005).
47. As a user, I want Board Events recorded while Sample Cards were on the Board to stay, since they are true facts about the Board (ADR 0005).
48. As a user, I want an action I undid to appear nowhere, since its event is gone (ADR 0002).
49. As a user, I want a sample store to show only that store's history, so that trying things doesn't touch my real Board.

Staying current

50. As a user, I want the open window to update after every change on the Board and once a minute, like my other windows, so that it never shows a stale state.
51. As a user, I want a plain "No Cards in this time span" when there's nothing to show, so that a new store doesn't look broken.
52. As a user, I want it to look right in light and dark, and the Sankey to fit the window's width, so that it's readable however I work.
53. As a user, I want colour never to be the only way to tell things apart, so that every part of the Sankey and the bars has a label or a legend.

## Implementation Decisions

- **The Board (KanbanCore)** gets one read-only query: the Dashboard's contents for a time span, computed together at one moment like the Board's state. It returns the Sankey's paths with their counts, the counts per week, the median and oldest Card per Column, the Cards kept repeatedly, the Creation Blocked count and the WIP Limit changes. It writes nothing. All the rules in this spec live there, and the window only displays the result.
- **No schema change and no new event.** Everything follows from the existing Card Events and Board Events.
- **A Card's path** is computed from where it stood when the time span began and where it stands now: its source is "Created" if it was created during the time span and "Already open" if it was an Open Card at the start; its target is its state now. A Card goes through Doing if it was in Doing at the start or entered Doing during the time span. It goes through Backlog unless it was already in Doing at the start.
- **A Card Discarded before the time span and Restored during it** counts as "Already open". This wasn't discussed in the grill: it's the reading that keeps the sums right and doesn't count the Card as Created (story 32). To be checked when the spec is reviewed.
- **The median** covers each time a Card left the Column during the time span, by a move or a Discard. For Backlog it's the Card Age at that moment; for Doing it's the Column Age at that moment.
- **A time span of N weeks** starts on the Monday N−1 weeks before the current week's Monday; All starts at the first event in the store. Weeks follow the calendar of the Mac's own time zone.
- **The Dashboard window** follows the Archive window: AppKit, its own window controller, opened through the same paths, frame remembered. It holds the time span's segmented control, the Sankey, the weekly bars and the lists. The chosen time span is stored with the store's settings.
- **The Sankey and the bars are drawn by hand** in AppKit, with no third-party library (spec 0001) and no macros (CLAUDE.md). Apple has no ready-made Sankey. Colours come from system colours, so that they adapt to light and dark and to Increase Contrast. Each target keeps one colour in the Sankey and the bars.
- **Hover texts** give exact numbers, and everything in them is also available in the table view.
- **Refresh**: the window is told of Board changes like the other windows, and has the same minute refresh while visible.
- **No ADR**: these decisions are easy to change, and no rule or schema is touched.

## Testing Decisions

- **One seam:** the new query on the Board's public interface, with the test clock and test events, as in the existing Board tests. Good tests state what the user would read ("a Card that went from Doing back to Backlog ends in Still in Backlog and has been through Doing"), not how the events are stored.
- **Paths:** the left side equals the right side for every case; Created versus Already open at the boundary; already in Doing at the start goes past Backlog; Doing and back; Discard then Restore counted by its end; Discarded before and Restored during the time span; Done or Discarded before the time span left out; Sample Cards left out.
- **Weekly counts:** week boundaries on Monday at midnight; a Discard counts in its week even after a Restore; a Restore adds nothing; an undone action counts nowhere; moving to Done counts even after the Card is archived.
- **Durations:** a median with an odd and even number of Cards; Discards included; visits added up for Doing; the oldest Card still there ignores the time span; "no value" cases.
- **Triage and Board Events:** kept twice is listed and once isn't; dismissed doesn't count; counts stay within the time span; Board Events from while Sample Cards were on the Board stay; a refused Restore isn't blocked.
- **Time spans:** 4 Weeks, 12 Weeks and All each start where they should, and an empty store returns an empty result.
- **Prior art:** the Archive tests, the Capacity tests, the Triage tests, the Restore tests and the Undo tests.
- **By hand on a sample store, with real input:** the window from all three ways in, resizing, the time span remembered, hover texts, light and dark, the accessibility tree and VoiceOver. The drawing itself isn't tested automatically, in line with spec 0001's "Not automated" list.

## Out of Scope

- Goals, scores, streaks, advice and warnings.
- Actions from the window, including opening a Card from a list in this first version.
- A custom date range or other settings besides the three time spans.
- A global hotkey for the Dashboard.
- Telling apart archiving by hand and after the Archive Delay.
- Exporting data.
- Any change to the Capacity or Urgency rules.

## Further Notes

- Tickets go in `.scratch/dashboard/issues/`, written after the review from 2026-12-01.
- A first look at the real data on 2026-11-09 showed a very short median time in Doing. That is a question for the review: it may mean Cards are moved to Doing only once the work is nearly done.
