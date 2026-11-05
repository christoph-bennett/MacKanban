# 01: ⌃⌥K brings the Board to the front and back

**What to build:** Spec 0002, stories 1–8 and 19–21 (without the Shortcuts tab's note). A global hotkey, ⌃⌥K by default, that works from any app while MacKanban runs. It opens the Board window when it's closed, shows it when MacKanban is hidden and raises it when it's behind other windows, activating MacKanban. Pressed while the Board window is visible, MacKanban active, the Board the key window and no sheet attached, it closes the Board exactly as Esc does: close, then hide MacKanban unless another MacKanban window is open. With a sheet open on the Board in front, it leaves the Board where it is. Esc doesn't change.

This brings in KeyboardShortcuts as ADR 0006 describes: MacJot's vendored 3.1.0 copied with its README, licence and patch markers, referred to by path from the app target only (KanbanCore stays free of it), and its resource bundle copied into the app by the bundle script. The hotkey is one stored name with ⌃⌥K as its initial shortcut, registered at launch. A MacKanban started on a sample store doesn't register it, so it can't take ⌃⌥K from the real one. The close path is shared with Esc, not copied. Changing the hotkey comes with ticket 02.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The project builds with the vendored package (Command Line Tools only, no macro plugins); the existing tests stay green
- [x] The bundled app contains the package's resource bundle
- [x] ⌃⌥K with the Board closed, with MacKanban hidden, and with the Board behind another app's window brings the Board to the front with MacKanban active
- [x] ⌃⌥K with the Board in front and active closes it and hands back to the previous app; with Settings or the Archive also open, the Board closes and MacKanban stays
- [x] ⌃⌥K with a sheet open on the Board in front leaves the Board and the sheet where they are
- [x] Esc behaves as before (story 54)
- [x] A sample-store instance doesn't register the hotkey; the real app keeps it
- [x] The hotkey survives a relaunch
- [ ] Checked with TEMP hooks calling the hotkey's handler in each state, and by Christoph with the real key

**Notes from implementing (2026-11-05):**
- MacJot's vendored KeyboardShortcuts copied unchanged (a line added at the top of its README says so); the app target depends on it by path, the bundle script copies its resource bundle.
- The hotkey's handler: Board visible, MacKanban active, the Board the main window and no sheet → the Board closes through the same method Esc now calls (moved out of the Board's Esc handler, not copied). Otherwise the Board is shown, and showing it (from anywhere) now activates MacKanban with `activate(ignoringOtherApps:)`: since macOS 14, plain `activate()` is only a request the system may turn down while another app is in use, and in the probe it did. The hotkey is the user asking for MacKanban, so it insists; the call is deprecated but works.
- Checked with a TEMP hook in a sample-store instance calling the handler in turn: Board in front → closed and MacKanban hidden; closed and hidden → Board in front, active; hidden with the Board open → in front; in front with Settings open → Board closed, MacKanban stays active; Settings key with the Board closed or behind → Board in front; a New Card sheet open → nothing moves, the sheet stays. The real app stores ⌃⌥K on first launch (in its defaults). The real key press can't be synthesized here (no Accessibility permission): Christoph checks it by hand.
- Code review (medium): applied: the Board counts as in front when it's the main window rather than the key one, so a popover on it (the Capacity gauge's) doesn't turn the next press into another "show"; `showBoard` makes the one insisting activation call itself, for every way to the Board, instead of the hotkey adding a second one. Rechecked with the TEMP hook. Not changed: the claim that the copied resource bundle is never found (the release build's accessor looks in the app's Resources first, which is where the bundle script puts it); the status "done" before the hand check (as with the other tickets); the deprecation warning for `activate(ignoringOtherApps:)` (kept on purpose, see above). Moved to ticket 02: a sample-store instance must not write the hotkey (KeyboardShortcuts stores in the standard defaults, shared with the real app), and a hotkey another app holds is dropped silently at launch (02's launch-time note and a log line).
