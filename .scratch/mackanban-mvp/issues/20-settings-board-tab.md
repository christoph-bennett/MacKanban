# 20: Settings gets a "Board" tab

**What to build:** Decided with Christoph on 2026-11-07 (grill about hiding the Dock icon). Settings gets a third tab, so its tabs read General, Board, Shortcuts. Board holds the two settings that change how Cards flow over the Board: the WIP Limit (the only rule the user can change, ADR 0001) and the Archive Delay (spec 0003), each with its note as today. General keeps Cards (Show ages on Cards) and Startup (Open MacKanban at login, with its approval row). Shortcuts stays as it is. Settings still opens on General every time. Nothing changes in how any setting works; they only move.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The tab switcher shows General, Board, Shortcuts, equally wide; the window's title names the tab, as today
- [ ] Board: WIP Limit and Archive Delay with their notes and spacing as on General today; changing either works as before (the Board and the Archive update at once, a WIP Limit change is recorded)
- [ ] General: only Cards and Startup; the approval row still appears only while Launch at login needs approval
- [ ] The window fits each tab at its natural size when switching; Esc still closes Settings; it reopens on General
- [ ] A sample-store instance shows the same tabs, with its own WIP Limit and Archive Delay
- [ ] Spec 0002 (which introduced the tabs) and spec 0003 (which put the Archive Delay in General) each get a dated note
- [ ] Screenshots of all three tabs in light and dark on a sample store; Christoph checks by hand
