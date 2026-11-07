# 18: Esc closes Settings

**What to build:** Asked for by Christoph on 2026-11-07. Esc closes the Settings window, as it closes the Board and the Archive, and as MacJot's Settings do. Whichever tab is showing, Esc closes the window (it opens on General next time, as now). While the Shortcuts tab's recorder is recording, Esc stays with the recorder (it cancels the recording) and doesn't close Settings; an open dropdown menu also takes Esc first.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Esc closes Settings on the General and the Shortcuts tab, like ⌘W
- [ ] While a hotkey recorder is recording, Esc cancels the recording and Settings stays open; the next Esc closes it
- [x] An open dropdown (WIP Limit, Archive Delay) closes on Esc without closing Settings
- [x] Closing with Esc behaves like ⌘W otherwise (next opening shows General)
- [ ] Checked by hand by Christoph (Esc needs a real key press; the terminal can't send one)

**Notes from implementing:**
- Esc closes Settings through `performClose`, as ⌘W does, from a small window subclass (as in MacJot). An override on the window controller didn't receive Esc when tried. Like the Archive's Esc, and unlike the Board's, it doesn't hide MacKanban afterwards (the ticket asks for "like ⌘W").
- While a recorder is recording, KeyboardShortcuts' event monitor ends the recording on Esc and swallows the key (checked in the vendored source), so Settings stays open. Not checked with a real key press: a sample-store instance has no recorder, and recording in the real app could change the real hotkey. Christoph checks it by hand (the criterion stays open until then).
- Checked with real key presses on a sample-store instance (System Events, aborting if MacKanban wasn't in front): Esc closes Settings on General; on Shortcuts too, and the next ⌘, opens on General; with the WIP Limit dropdown open, the first Esc closes the dropdown and Settings stays, the second closes Settings. 108 tests pass (no Board change).
- Review (medium): the comment no longer claims Esc works "as on the Board" (no hand-back) and says why the subclass; the recorder's Esc handling was checked in the source.
