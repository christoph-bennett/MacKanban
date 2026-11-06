# 01: Archive Delay setting

**What to build:** How long Done Cards stay on the Board before they go to the Archive on their own, the Archive Delay, becomes my choice under Settings > General: a dropdown like the WIP Limit's with 1, 2, 3, 5 and 7 days, 3 by default (also on the first launch after this update). A change applies at once to every Done Card: shortening it archives older Done Cards straight away, lengthening it brings them back. The fixed 7-day constant goes away. Spec 0003 stories 18–25, 41–43; ADR 0007.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The Board is created with the stored Archive Delay, like the WIP Limit; allowed values 1, 2, 3, 5, 7 days; default 3 days; a stored value outside them becomes the default
- [ ] The Board can change the Archive Delay; a change writes no event and applies at once to Board state and the Archive query
- [ ] Settings > General has an "Archive Delay:" row with a dropdown ("1 day" … "7 days") and the note "How long Done Cards stay on the Board before they go to the Archive. Archiving early doesn't change Throughput."
- [ ] The choice survives relaunching; a sample-store instance keeps its own value, as for the WIP Limit
- [ ] A change refreshes the Board window and an open Archive window
- [ ] A Done Card leaves the Board within a minute of its Done visit reaching the Archive Delay
- [ ] Throughput and Capacity are unchanged by the delay (a Card archived after 3 days still counts until 14 days after it was finished)
- [ ] Board tests: default 3 days (visible just before, archived at 3 days); shortening and lengthening the delay archive and bring back Done Cards; out-of-range stored value → default; no event written. The existing 7-day archive tests are rewritten against the configurable delay
- [ ] Spec 0001 gets a dated note that stories 15–16 and the Defaults line's "7-day Archive delay" are superseded by spec 0003
- [ ] Screenshot of Settings > General on a sample store
