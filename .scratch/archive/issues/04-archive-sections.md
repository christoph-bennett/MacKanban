# 04: Archive window with Done and Discarded sections

**What to build:** The Archive window shows two sections, Done first, then Discarded, each with a heading and each newest first, instead of one mixed list with an Outcome column. Columns: Card, Created, Ended (the section heading says whether that's finished or Discarded). Empty sections are hidden. Keyboard use and read-only opening stay as they are. Spec 0003 stories 26–31, 35–38.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The Board's Archive query returns Done entries and Discarded entries separately, each newest first; a Done entry is dated and sorted by when it entered Done
- [ ] The window shows group rows "Done" and "Discarded" (not selectable, skipped by ↑↓), columns Card | Created | Ended, no Outcome column
- [ ] A section with no Cards is hidden; "Nothing in the Archive yet." when both are empty
- [ ] Return and double-click open a Card read-only as today; Esc closes; the selected Card stays selected across reloads; reloads after Board changes and once a minute while open
- [ ] VoiceOver announces the section names
- [ ] Board tests: the split and the order of both lists (extending the existing archive tests)
- [ ] Screenshots on a sample store: both sections; only one section; empty Archive
