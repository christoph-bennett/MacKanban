# 03: Option to hide MacKanban from the Dock

**What to build:** Spec 0004, stories 15–26. Settings > General gets a row after Startup: "Dock:" with a checkbox "Show MacKanban in the Dock" and the note "When off, MacKanban runs from the menu bar and its hotkeys, and isn't in the Dock or the app switcher." On by default, so nothing changes until it's switched off. Switched off, the Dock icon goes at once, without relaunching, and MacKanban leaves the app switcher (⌘Tab); switched on, it comes back at once. The menu bar extra, both hotkeys and every window (Board, Archive, Settings) keep working. The choice survives relaunching; a sample store has its own, as with the WIP Limit.

Without the Dock icon macOS doesn't show MacKanban's own menu bar. Whether the key equivalents still work then (⌘N, ⌘Z and ⇧⌘Z, ⌘⌫, ⌘→ and ⌘←, ⌘⇧A, ⌘0, ⌘,, ⌘W, ⌘Q, and Esc) is checked here; if some don't, tell Christoph what fails and agree a fix before changing anything about it.

**Blocked by:** 01 (Settings gets a "Board" tab), 02 (Open Archive from the menu bar extra)

**Status:** done

- [x] General shows Cards, Startup, then "Dock:" with the checkbox and its note, in MacKanban's Settings spacing
- [x] Off: the Dock icon disappears at once and MacKanban isn't in ⌘Tab; the open windows stay where they are and the Board still comes forward from the menu bar extra and the Show Board hotkey
- [x] On again: the Dock icon is back at once, and clicking it with the Board closed opens the Board, as today
- [x] Off survives relaunching (no Dock icon flashing up at launch); a sample store's setting doesn't change the real one
- [x] With the Dock icon off, the key equivalents listed above are checked one by one, with the result in the Notes
- [x] The New Card hotkey still hands back to the previous app after its sheet closes, with the Dock icon off
- [x] Screenshots of General in light and dark; checked on a sample store; Christoph checks by hand

**Notes from implementing:**
- The bundle now starts as an app without a Dock icon (`LSUIElement`), and MacKanban switches itself to a normal app at launch, before any window shows, while the setting is on. That's what keeps an icon from flashing up when it's off: macOS shows a normal app's Dock icon before the app's own code runs. Checked by polling the app's type every 50 ms from launch with the setting off: never a normal app.
- Switching off makes macOS deactivate MacKanban twice, about 50 ms apart; reactivating brought only the key window back, so the Board fell behind the app below it. Seen in a log of the activation events. After a switch MacKanban now waits until the deactivations have settled (0.2 s quiet, within a second), then activates and puts its windows back in the order they had; windows closed meanwhile stay closed, a quick back-and-forth uses the first order. The timings are measured, not documented by Apple: if a later macOS behaves differently, the Board could fall behind again (a fallback after 0.2 s covers a switch without a second deactivation).
- Switching on also reactivates MacKanban; that's what makes its menu bar appear at once (checked by screenshot of the menu bar; without the Dock icon the menu bar shows the previous app's menus, as expected).
- Key equivalents with the Dock icon off, checked one by one on a sample store with real keystrokes (each sent only if the sample MacKanban was frontmost): ⌘W (Settings, Archive, Board), ⌘, and Esc (Settings), ⌘⇧A (Archive), ⌘0 (Board), ⌘N (New Card sheet), Return (saves the Card), ⌘Z and ⇧⌘Z (Card created, undone, redone), ⌘← and ⌘→ (a Doing Card to Backlog and back), ⌘⌫ (Discard) and ⌘Z, ⌘Q (quits). All work: the app's menus still handle their key equivalents though macOS doesn't show them. Nothing to agree with Christoph.
- Also checked with the Dock icon off: Open Board from the menu bar extra with Terminal in front; the New Card hotkey (TEMP signal hook, since removed) opens the sheet from Terminal and hands back to Terminal after Cancel. The Dock-icon click with the Board closed is unchanged code (not clicked here).
- Settings spacing: the 16 pt between settings now comes from space above a labelled row rather than below the row before, since that row can be hidden (Launch at login's approval row sat directly above Dock with no gap). The Shortcuts tab keeps 20 pt between its two hotkeys and lost 20 pt of extra space at its bottom, so all tabs end alike.
- Review (medium) fixes: closed windows stay closed after a switch; quick toggling keeps the first window order; no restore after the switch has settled (a later deactivation is the user's); the Shortcuts spacing loop simplified. Kept: the restore on switching on (it brings the menu bar); starting as an app without a Dock icon (the price of no flash).
- Checked by hand by Christoph on 2026-11-08.
