# 05: Counts column

**What to build:** In the Archive's Done section a Counts column shows how much longer each Card counts toward Throughput: a small bar that drains from full on the day it was finished to empty 14 days later, and "until Nov 10" (short date in my locale). A Card whose 14 days are over shows "no longer", and its whole row is greyed out. Spec 0003 stories 32–34, 39, 40.

**Blocked by:** 04 (Archive window with Done and Discarded sections)

**Status:** ready-for-agent

- [ ] A Done entry from the Archive query carries the end of its Throughput window: Done date + the Capacity Throughput window (the same constant, not a copy)
- [ ] The Counts cell shows a level-indicator-style bar draining linearly over the 14 days plus "until <short date>"; expired: "no longer", and all the row's cells in the secondary label colour
- [ ] The Counts cell is empty for Discarded rows
- [ ] VoiceOver reads "Counts toward Throughput until <date>" or "No longer counts toward Throughput"
- [ ] The bar is readable in light and dark mode and with Increase Contrast
- [ ] Board test: the window end is Done + 14 days, also for a hand-archived Card (if 02 is done) and for one archived by the delay
- [ ] Screenshots on a sample store with counting and expired rows, light and dark
