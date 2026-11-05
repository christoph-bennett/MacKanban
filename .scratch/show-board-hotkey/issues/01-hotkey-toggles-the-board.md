# 01: ⌃⌥K brings the Board to the front and back

**What to build:** Spec 0002, stories 1–8 and 19–21 (without the Shortcuts tab's note). A global hotkey, ⌃⌥K by default, that works from any app while MacKanban runs. It opens the Board window when it's closed, shows it when MacKanban is hidden and raises it when it's behind other windows, activating MacKanban. Pressed while the Board window is visible, MacKanban active, the Board the key window and no sheet attached, it closes the Board exactly as Esc does: close, then hide MacKanban unless another MacKanban window is open. With a sheet open on the Board in front, it leaves the Board where it is. Esc doesn't change.

This brings in KeyboardShortcuts as ADR 0006 describes: MacJot's vendored 3.1.0 copied with its README, licence and patch markers, referred to by path from the app target only (KanbanCore stays free of it), and its resource bundle copied into the app by the bundle script. The hotkey is one stored name with ⌃⌥K as its initial shortcut, registered at launch. A MacKanban started on a sample store doesn't register it, so it can't take ⌃⌥K from the real one. The close path is shared with Esc, not copied. Changing the hotkey comes with ticket 02.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The project builds with the vendored package (Command Line Tools only, no macro plugins); the existing tests stay green
- [ ] The bundled app contains the package's resource bundle
- [ ] ⌃⌥K with the Board closed, with MacKanban hidden, and with the Board behind another app's window brings the Board to the front with MacKanban active
- [ ] ⌃⌥K with the Board in front and active closes it and hands back to the previous app; with Settings or the Archive also open, the Board closes and MacKanban stays
- [ ] ⌃⌥K with a sheet open on the Board in front leaves the Board and the sheet where they are
- [ ] Esc behaves as before (story 54)
- [ ] A sample-store instance doesn't register the hotkey; the real app keeps it
- [ ] The hotkey survives a relaunch
- [ ] Checked with TEMP hooks calling the hotkey's handler in each state, and by Christoph with the real key
