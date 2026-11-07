# 17: Global hotkey for a New Card

**What to build:** Asked for by Christoph on 2026-11-07 (BACKLOG, moved from Later to MVP). A second global hotkey, beside Show Board (spec 0002), brings the Board to the front from any app and opens the New Card sheet on it, exactly as ⌘N does: through the creation gate, so a blocked attempt is recorded and Triage appears when it would with ⌘N (spec 0001, ADR 0001). No quick-add panel of its own (decided 2026-11-07). Settings > Shortcuts gets a second recorder, "New Card", below "Show Board".

**Blocked by:** None (can start immediately; reuses spec 0002's KeyboardShortcuts setup, ADR 0006)

**Status:** ready-for-agent

- [ ] A second KeyboardShortcuts name with its own default combination ⌃⌥⇧K (confirmed by Christoph on 2026-11-07; it doesn't collide with Show Board ⌃⌥K or MacJot's ⌃⌥N and ⌃⌥F), stored like the first
- [ ] The hotkey activates MacKanban, shows the Board window (open, unhide or bring forward, as Show Board does) and opens the New Card sheet through the same path as ⌘N
- [ ] If a sheet is already open on the Board, the hotkey only brings the Board forward and opens nothing new
- [ ] If MacKanban wasn't in front before the hotkey, closing the sheet (saved or cancelled) closes the Board like Esc and hands back to the app Christoph came from; otherwise the Board stays (confirmed by Christoph on 2026-11-07)
- [ ] Settings > Shortcuts: a "New Card" recorder below "Show Board", with clear and Restore Default, the same refusals as Show Board's (menu combinations, system combinations, another app holding it) and also refusing Show Board's current combination (and vice versa)
- [ ] The "couldn't be registered" note covers either hotkey; a sample-store instance registers neither and says so
- [ ] Both hotkeys survive relaunching; MacKanban's menus don't show them
- [ ] Spec 0002: a dated note that a New Card hotkey was added (it listed it as out of scope)
- [ ] Checked with TEMP hooks on a sample store (Board closed, hidden, behind, in front, with a sheet; a blocked creation), screenshots of the Shortcuts tab light and dark; Christoph checks the real hotkey by hand
