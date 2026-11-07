# 05: Counts column

**What to build:** In the Archive's Done section a Counts column shows how much longer each Card counts toward Throughput: a small bar that drains from full on the day it was finished to empty 14 days later, and "until Nov 10" (short date in my locale). A Card whose 14 days are over shows "no longer", and its whole row is greyed out. Spec 0003 stories 32–34, 39, 40.

**Blocked by:** 04 (Archive window with Done and Discarded sections)

**Status:** done

- [x] A Done entry from the Archive query carries the end of its Throughput window: Done date + the Capacity Throughput window (the same constant, not a copy)
- [x] The Counts cell shows a level-indicator-style bar draining linearly over the 14 days plus "until <short date>"; expired: "no longer", and the row faded (changed, see the notes)
- [x] The Counts cell is empty for Discarded rows
- [x] VoiceOver reads "Counts toward Throughput until <date>" or "No longer counts toward Throughput"
- [x] The bar is readable in light and dark mode and with Increase Contrast (light and dark checked; Increase Contrast not switched on, see the notes)
- [x] Board test: the window end is Done + 14 days, also for a hand-archived Card (if 02 is done) and for one archived by the delay
- [x] Screenshots on a sample store with counting and expired rows, light and dark

**Notes from implementing:**
- Board: a Done entry carries `countsUntil` (14 days after it entered Done, from Capacity's `throughputWindow`) and `isCounting`; the Archive carries `asOf`, the Board-clock moment it was read. One rule decides whether a Card counts, for Capacity's Throughput and for the Archive alike (`countsUntil >= now`), so the column can't drift from Capacity. Discarded entries have no `countsUntil` and never count.
- Window: a Counts column (fixed 140 pt) with a level-indicator bar that drains over the 14 days, measured from `asOf`, and "until 17. Nov" (short date in the user's locale); an expired Card shows "no longer" without a bar. The row fades: title in secondary, the other cells in tertiary colour. The ticket said "all cells secondary", but the date cells are secondary already, so that wouldn't have shown. VoiceOver reads "Counts toward Throughput until 17. Nov" / "No longer counts toward Throughput"; the bar itself is hidden from VoiceOver. The Card column absorbs width changes (the window's size is remembered); the minimum window width is now 600, the default 780.
- Tests: `countsUntil` for a Card archived by delay and one by hand; at a minute before, exactly at, and a minute after `countsUntil`, `isCounting` matches Capacity's Throughput; Discarded never counts. 112 tests pass.
- Review (medium) fixes: one Throughput rule and the Board's clock instead of the view's own boundary checks with `Date()` (the cell, the greying and Capacity disagreed at the boundary); `countsUntil`/`isCounting` immutable; stronger fading; a test states the Archive Delay it relies on.
- Checked by screenshot on a sample store: light and dark (a TEMP hook set the app's appearance to dark, since removed), a selected row, counting and expired rows. Increase Contrast wasn't switched on (it's a system-wide setting); the bar and labels use system colours.
- Added on 2026-11-07 at Christoph's request: hovering the bar shows how many days the Card still counts ("Counts for 10 more days", "Counts for 1 more day", "Counts for less than a day more"; whole days, rounded down, from the Archive's `asOf`). The date beside the bar stays. Checked with a real mouse hover (cliclick) on a sample store.
- Changed on 2026-11-07 at Christoph's request: the first hover text appeared only after the system's slow initial delay (later ones are quick). MacKanban now registers `NSInitialToolTipDelay` = 300 ms. This applies to every hover text in MacKanban (also the pencil, the Capacity gauge, the New Card button), not only the bars. Checked with a real mouse hover on a sample store: at 0.6 s the text is there (before: not yet).
- Fixed on 2026-11-07 after Christoph's check: two bars of different length ("Bug fixes", 10 days 22 hours left; "App Management", 10 days 6 hours) both said "Counts for 10 more days", because the text rounded down to whole days. It now says days and hours: "Counts for another 10 days and 22 hours" ("another 3 hours" under a day, "less than an hour more" at the end). Checked on a copy of the real Board by reading every bar's hover text.
- Checked by hand by Christoph on 2026-11-07.
- Decided by Christoph on 2026-11-07: the 0.3 s first hover text is right everywhere (also the New Card button), so the bars need no solution of their own.
