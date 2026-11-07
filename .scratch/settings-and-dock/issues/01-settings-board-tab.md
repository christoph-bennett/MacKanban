# 01: Settings gets a "Board" tab

**What to build:** Spec 0004, stories 1–10. Settings gets a third tab, so its tabs read General, Board, Shortcuts. Board holds the two settings that change how Cards flow over the Board: the WIP Limit (the only rule the user can change, ADR 0001) and the Archive Delay (spec 0003), each with its note as today. General keeps Cards (Show ages on Cards) and Startup (Open MacKanban at login, with its approval row). Shortcuts stays as it is. Settings still opens on General every time. Nothing changes in how any setting works; they only move. No Board change.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The tab switcher shows General, Board, Shortcuts, equally wide; the window's title names the tab, as today
- [x] Board: WIP Limit and Archive Delay with their notes and spacing as on General today; changing either works as before (the Board and the Archive update at once, a WIP Limit change is recorded)
- [x] General: only Cards and Startup; the approval row still appears only while Launch at login needs approval
- [x] The window fits each tab at its natural size when switching; Esc still closes Settings; it reopens on General
- [x] A sample-store instance shows the same tabs, with its own WIP Limit and Archive Delay
- [x] Screenshots of all three tabs in light and dark on a sample store; Christoph checks by hand

**Notes from implementing:**
- Each tab has its own grid, built by one helper that applies MacKanban's Settings spacing: 4 pt between a control and its note, 16 pt between settings, worked out from the rows (a row without a label gets the extra 12 pt when a labelled row follows). The Shortcuts tab uses the same helper and keeps its own extra spacing between the two hotkeys.
- Each tab shows at its natural width, as before. Since "Archive Delay:" is longer than General's labels, General is a little narrower than Board, and the tab switcher moves a few points when switching between them. Left as is; Christoph is fine with it (2026-11-07).
- Review (medium) fixes: a local name that hid the Board model; the Shortcuts grid and the note width use the shared helpers; the spacing no longer depends on a hand-kept list of notes.
- Checked by screenshot on a sample store (TEMP hook to open a given tab, since removed): General, Board and Shortcuts in light, General and Board in dark, Shortcuts with the recorders; the spacing is the same as on the old General tab. How the WIP Limit and Archive Delay act is unchanged code. 115 tests pass.
- Checked by hand by Christoph on 2026-11-07.
