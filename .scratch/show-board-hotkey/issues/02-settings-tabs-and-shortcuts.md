# 02: Settings tabs and the Shortcuts tab

**What to build:** Spec 0002, stories 9–18, 21 (the note) and 22. Settings get a toolbar with a centred segmented switcher between **General** and **Shortcuts**, modelled on MacJot's Settings, and the window resizes to the selected tab; its title follows the tab. General holds exactly what Settings holds today (WIP Limit, Show ages on Cards, Launch at login), unchanged. Settings stay AppKit, since the WIP Limit goes through the Board.

Shortcuts shows the package's AppKit recorder for "Show Board", its text centred (MacJot's patch), and a "Restore Default" button for ⌃⌥K. Recording a combination: the package refuses ones MacKanban's menus use and warns about ones macOS uses; before saving, MacKanban tries a short system registration and, if that fails, rejects the combination with "MacKanban can't use this combination. Another app may be using it." and keeps the previous one. The hotkey can be cleared. Restore Default says so and keeps the current hotkey if another app holds ⌃⌥K. A note line says when the saved hotkey couldn't be registered at launch, until it's recorded or restored; in a sample-store instance it says the hotkey isn't active there. Recorder and button are labelled for VoiceOver and reachable by keyboard. The "one pane" note from the HIG audit (finding 6) in the Settings code goes.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Settings open on a tab switcher with General and Shortcuts; General looks and works as Settings did; the title follows the tab; the window fits each tab
- [ ] The recorder shows ⌃⌥K centred; recording another combination changes the hotkey at once, and it survives a relaunch
- [ ] ⌘N (or another menu combination) is refused with the package's reason; a combination another app holds is refused with MacKanban's message, and the previous hotkey stays
- [ ] Clearing the recorder leaves MacKanban without a global hotkey
- [ ] Restore Default sets ⌃⌥K again
- [ ] The launch-time "couldn't be registered" note and the sample-store note show when they apply
- [ ] Screenshots of both tabs in light and dark; checked by Christoph by hand
- [ ] Spec 0001's Settings decision gets a dated note pointing to spec 0002

**Notes from ticket 01 (2026-11-05):**
- KeyboardShortcuts stores the hotkey in the standard defaults, which a sample-store instance shares with the real app (its own settings live in a separate suite). So in a sample-store instance the Shortcuts tab shows only its note, with no recorder or Restore Default, or recording there would change the real app's hotkey.
- When another app holds the saved combination at launch, the package drops the registration without a word. Check it before registering (as MacJot does), log it, and show the launch-time note.
