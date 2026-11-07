# 18: Esc closes Settings

**What to build:** Asked for by Christoph on 2026-11-07. Esc closes the Settings window, as it closes the Board and the Archive, and as MacJot's Settings do. Whichever tab is showing, Esc closes the window (it opens on General next time, as now). While the Shortcuts tab's recorder is recording, Esc stays with the recorder (it cancels the recording) and doesn't close Settings; an open dropdown menu also takes Esc first.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Esc closes Settings on the General and the Shortcuts tab, like ⌘W
- [ ] While a hotkey recorder is recording, Esc cancels the recording and Settings stays open; the next Esc closes it
- [ ] An open dropdown (WIP Limit, Archive Delay) closes on Esc without closing Settings
- [ ] Closing with Esc behaves like ⌘W otherwise (next opening shows General)
- [ ] Checked by hand by Christoph (Esc needs a real key press; the terminal can't send one)
