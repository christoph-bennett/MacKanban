# 02: Open Archive from the menu bar extra

**What to build:** Spec 0004, stories 11–14. The menu bar extra's menu gets "Open Archive" right under "Open Board", so its last group reads New Card…, Open Board, Open Archive, Settings…. It opens the Archive window and brings MacKanban to the front, as Window > Archive (⌘⇧A) does. No key equivalent is shown, like the other items there. Needed before the Dock icon can be hidden (ticket 03): without the Dock icon the app's menu bar isn't shown, and the Archive would only be reachable by ⌘⇧A.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] "Open Archive" sits between "Open Board" and "Settings…" in the menu bar extra's menu
- [x] It opens the Archive window (or brings it forward if open, unminimizes it if minimized) with MacKanban in front, from any app
- [x] VoiceOver reads it as "Open Archive"
- [x] Checked on a sample store; screenshot of the menu; Christoph checks by hand

**Notes from implementing:**
- "Open Archive" calls the same path as Window > Archive (⌘⇧A).
- Found while checking: from the menu bar extra with another app in front, the Archive window opened but MacKanban stayed behind; Settings… did the same. Both asked macOS to activate MacKanban with the plain call, which it may turn down while another app is in use; only Open Board insisted. All the ways the user asks for a MacKanban window now use one insisting activation: Open Board, Open Archive, Settings…, Move to Done and the Sample Cards items while a sheet is up, an error shown with the Board hidden, and the alert when the Board can't be opened at launch. Settings, like the Archive, also comes in front of an open Board. Outside the ticket's text, but the same bug in the same menu, and the menu bar extra becomes the main way in once the Dock icon can be hidden (ticket 03).
- Review (medium) fixes: the launch alert and Settings' window order (above); a second, weaker activation at launch removed; the shared activation in its own file. Kept: the Archive window ordered front twice (harmless); Move to Done activating insistently (only reached from the menu bar extra).
- Checked on a sample store with the real MacKanban quit (System Events finds apps by name), through Accessibility menu clicks: with Terminal in front, Open Archive, Settings… and Open Board each bring MacKanban to the front with their window first, also with the Board open; a minimized Archive comes back, and there is still one Archive window; VoiceOver's name for the item is "Open Archive". Screenshot of the menu. 115 tests pass.
- Checked by hand by Christoph on 2026-11-07.
