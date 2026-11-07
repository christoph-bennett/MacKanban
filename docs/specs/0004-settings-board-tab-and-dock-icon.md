# Spec 0004 — Settings: a Board tab, Open Archive in the menu bar extra, hiding the Dock icon

Status: ready-for-agent

Vocabulary follows [GLOSSARY.md](../../GLOSSARY.md) (Board, WIP Limit, Archive Delay, Archive). Leaves [ADR 0001](../adr/0001-capacity-and-urgency-rules.md) untouched: the WIP Limit stays the only rule the user can change. Designed with Christoph on 2026-11-07 (grill about hiding the Dock icon). It changes spec 0002's two Settings tabs and the place spec 0003 gave the Archive Delay (Settings > General).

## Problem Statement

MacKanban lives in my menu bar and comes up with a hotkey, so I rarely need it in the Dock, where it takes room and adds itself to the app switcher. I can't turn the Dock icon off. Settings > General also mixes two kinds of settings: the rules of my Board (WIP Limit, Archive Delay) sit beside how the app looks and starts (ages on Cards, Launch at login), and a Dock option would make that list longer still. And without the Dock icon, macOS doesn't show MacKanban's menu bar, so the Archive, which only Window > Archive opens, would be reachable by ⌘⇧A alone.

## Solution

Settings gets three tabs: General, Board, Shortcuts. Board holds the WIP Limit and the Archive Delay. General keeps Cards (ages on Cards) and Startup (Launch at login) and gets a new row, Dock, with "Show MacKanban in the Dock", on by default. When I switch it off, the Dock icon goes at once and MacKanban leaves the app switcher; the menu bar extra, both hotkeys and every window keep working. The menu bar extra gets "Open Archive" under "Open Board", so everything stays reachable without the app's menu bar. Shortcuts doesn't change.

## User Stories

Settings tabs

1. As a user, I want Settings in three tabs, General, Board and Shortcuts, so that I find a setting by what it's about.
2. As a user, I want the WIP Limit and the Archive Delay on a tab named Board, so that the rules for how Cards flow over my Board are together.
3. As a user, I want each of them to keep its explanation under it, so that the move costs me nothing.
4. As a user, I want General to keep Cards (Show ages on Cards) and Startup (Open MacKanban at login), so that how the app looks and starts stays in one place.
5. As a user, I want the Shortcuts tab exactly as it is, so that my hotkeys aren't touched.
6. As a user, I want Settings to open on General every time, as today, so that it always starts in the same place.
7. As a user, I want the window to fit each tab when I switch, as today, so that no tab is squeezed or padded.
8. As a user, I want Esc to keep closing Settings on every tab, so that the new tab behaves like the others.
9. As a user, I want a WIP Limit or Archive Delay change on the Board tab to show on the Board and in the Archive at once, as today, so that moving the settings changes nothing about what they do.
10. As a user, I want a MacKanban opened on a sample store to show the same tabs with its own settings, so that trying things never changes my real Board.

Open Archive from the menu bar extra

11. As a user, I want "Open Archive" in the menu bar extra's menu, right under "Open Board", so that I reach the Archive without the app's menu bar.
12. As a user, I want it to open the Archive window with MacKanban in front from any app, as ⌘⇧A does, so that it works the same whichever way I get there.
13. As a user, I want it to bring forward or unminimize an Archive window that's already open, so that I never get a second one.
14. As a user, I want no shortcut shown beside it, like the other items in that menu, so that the menu stays calm.

Hiding the Dock icon

15. As a user, I want a checkbox "Show MacKanban in the Dock" in Settings > General, in its own row "Dock:" after Startup, so that I decide whether MacKanban takes room in my Dock.
16. As a user, I want it on by default, so that nothing changes until I choose.
17. As a user, I want a note under it, "When off, MacKanban runs from the menu bar and its hotkeys, and isn't in the Dock or the app switcher.", so that I know what I give up.
18. As a user, I want the Dock icon to go the moment I switch it off, without relaunching, so that I see the effect right away.
19. As a user, I want MacKanban out of the app switcher (⌘Tab) while it's off, so that switching apps only shows apps I use as apps.
20. As a user, I want my open windows to stay where they are when I switch it, so that nothing jumps away.
21. As a user, I want the Board to keep coming forward from the menu bar extra and the Show Board hotkey while it's off, so that I can always get to it.
22. As a user, I want the New Card hotkey to keep working while it's off, including going back to the app I came from, so that capturing a Card works the same.
23. As a user, I want the Dock icon back at once when I switch it on again, and a click on it to open the Board as today, so that the choice is easy to undo.
24. As a user, I want my choice kept across relaunches, without the Dock icon flashing up at launch, so that it stays the way I set it.
25. As a user, I want a MacKanban opened on a sample store to keep its own Dock choice, so that trying it never changes my real app.
26. As a user, I want MacKanban's keyboard shortcuts (⌘N, ⌘Z, ⇧⌘Z, ⌘⌫, ⌘→, ⌘←, ⌘⇧A, ⌘0, ⌘,, ⌘W, ⌘Q, Esc) to keep working while the Dock icon is off, so that I don't lose them with the menu bar; if some can't, I want to hear which before anything is changed about it.

## Implementation Decisions

- **No Board change.** KanbanCore, the store and the event log are untouched; no schema change (ADR 0002). The WIP Limit and the Archive Delay still go through the Board when changed; only their place in Settings moves.
- **Settings tabs:** the existing toolbar switcher gets a third segment; the order is General, Board, Shortcuts, all equally wide. The window title names the current tab, as today. The Board tab is built from the two rows that leave General, with their notes and MacKanban's Settings spacing (4 pt between a control and its note, 16 pt between settings). Settings still switches back to General after it closes.
- **General:** Cards, Startup (with the approval row shown only while Launch at login needs approval), then Dock: a checkbox "Show MacKanban in the Dock" and its note.
- **Dock setting:** a Boolean in the app's defaults, on by default, like "Show ages on Cards"; a sample store's separate defaults apply. Switching it changes the app's activation policy at runtime: regular (Dock icon, app switcher, menu bar) when on, accessory when off. At launch the stored choice is applied before any window shows, so an off setting never flashes a Dock icon.
- **Menu bar extra:** a new item "Open Archive" between "Open Board" and "Settings…", doing what Window > Archive does (open or bring forward the Archive window, activate MacKanban). No key equivalent shown.
- **Key equivalents without the menu bar:** checked by hand while the Dock icon is off (ticket 03). If some don't reach MacKanban, the finding goes to Christoph first; a fix (for example handling them in the windows themselves) is agreed before it's built.
- **Dock icon click:** with the setting on, a click on the Dock icon with the Board closed still opens the Board (unchanged reopen behaviour).

## Testing Decisions

- **No new test seam.** Nothing in this spec changes the Board, so there are no new Board tests; the existing suite must stay green. The app target has no test target; its windows and menus are checked by hand, as throughout this project.
- **Checked on sample stores** with temporary hooks where needed (removed before committing), as in the earlier specs: screenshots of all three Settings tabs in light and dark; the menu bar extra's menu; the Dock setting switched off and on (Dock icon and app switcher, windows staying put, the Board from the menu bar extra and the Show Board hotkey, the New Card hotkey's hand-back); the key equivalents one by one with the Dock icon off; a relaunch with it off.
- Then Christoph checks each ticket by hand on his real MacKanban.
- Prior art: spec 0002's checks of the Settings tabs and hotkeys, MVP ticket 17's checks of the hand-back (signal hook, Accessibility button presses).

## Out of Scope

- Hiding the menu bar extra (MacKanban needs one way in without the Dock).
- Hiding the Dock icon only while no window is open.
- Changing the Shortcuts tab or adding hotkeys (for example one for the Archive).
- New settings on the Board tab, or settings for Capacity or Urgency (ADR 0001).
- Remembering the last Settings tab.

## Further Notes

- Tickets: [.scratch/settings-and-dock/issues/](../../.scratch/settings-and-dock/issues/README.md).
- Settings switches tabs the way MacJot does (spec 0002); a third tab follows the same pattern.
