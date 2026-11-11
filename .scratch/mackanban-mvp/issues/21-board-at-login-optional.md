# 21: Open the Board at login only when asked

**What to build:** When MacKanban starts at login, it starts quietly: no window opens and it doesn't come to the front. The menu bar extra, both hotkeys and the Dock icon (if shown) are there as usual. Requested 2026-11-11: today the Board opens at every login, which goes against story 39 ("so that the menu bar extra can be there from startup"). Christoph wants the old behaviour kept as an option.

Settings > General > Startup gets a second checkbox, indented under "Open MacKanban at login": "Open the Board at login", off by default. When it's on, a login launch opens the Board as today. It can only be changed while Launch at login is on; otherwise it's dimmed and keeps its value. Like the other settings it lives in the app's defaults, so a sample store has its own.

Only launches at login change. Starting MacKanban by hand (Finder, Spotlight, Dock, after an install) still opens the Board, and clicking the Dock icon while no window is open still shows it. No spec of its own: a follow-up to story 39 of spec 0001.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] With the new checkbox off, logging out and in starts MacKanban with no window open and without making it the active app; the menu bar extra and both hotkeys work
- [ ] With it on, logging out and in opens the Board as before
- [ ] A launch by hand opens the Board, whatever the checkbox says
- [ ] After a quiet start, clicking the Dock icon (when shown) opens the Board
- [ ] The checkbox sits under "Open MacKanban at login" in General > Startup, is off by default, is dimmed while Launch at login is off, and keeps its choice across relaunches
- [ ] Its label and hover text read clearly, and VoiceOver announces it with its dimmed state
- [ ] Spec 0001 gets a dated note under story 39 and in Settings and Defaults
- [ ] Checked by hand by Christoph on the real login (logout and login, both settings)
