# 22: Option to hide MacKanban from the Dock

**What to build:** Asked for by Christoph on 2026-11-07. Settings > General gets a row after Startup: "Dock:" with a checkbox "Show MacKanban in the Dock" and the note "When off, MacKanban runs from the menu bar and its hotkeys, and isn't in the Dock or the app switcher." On by default, so nothing changes until it's switched off. Switched off, the Dock icon goes at once, without relaunching, and MacKanban leaves the app switcher (⌘Tab); switched on, it comes back at once. The menu bar extra, both hotkeys and every window (Board, Archive, Settings) keep working. The choice survives relaunching; a sample store has its own, as with the WIP Limit.

Without the Dock icon macOS doesn't show MacKanban's own menu bar. Whether the key equivalents still work then (⌘N, ⌘Z and ⇧⌘Z, ⌘⌫, ⌘→ and ⌘←, ⌘⇧A, ⌘0, ⌘,, ⌘W, ⌘Q, and Esc) is checked here; if some don't, tell Christoph what fails and agree a fix before changing anything about it.

**Blocked by:** 20 (Settings gets a "Board" tab), 21 (Open Archive from the menu bar extra)

**Status:** ready-for-agent

- [ ] General shows Cards, Startup, then "Dock:" with the checkbox and its note, in MacKanban's Settings spacing
- [ ] Off: the Dock icon disappears at once and MacKanban isn't in ⌘Tab; the open windows stay where they are and the Board still comes forward from the menu bar extra and the Show Board hotkey
- [ ] On again: the Dock icon is back at once, and clicking it with the Board closed opens the Board, as today
- [ ] Off survives relaunching (no Dock icon flashing up at launch); a sample store's setting doesn't change the real one
- [ ] With the Dock icon off, the key equivalents listed above are checked one by one, with the result in the Notes
- [ ] The New Card hotkey still hands back to the previous app after its sheet closes, with the Dock icon off
- [ ] Screenshots of General in light and dark; checked on a sample store; Christoph checks by hand
