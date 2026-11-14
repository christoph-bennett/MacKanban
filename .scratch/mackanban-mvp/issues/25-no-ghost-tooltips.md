# 25: No ghost tooltips while the Board is hidden

**What to build:** While MacKanban sits in the menu bar with its windows closed, no hover text of its own appears on screen. Reported 2026-11-14: a Card's hover text popped up with no touch, at irregular intervals, and went away once the Board was shown again with its hotkey. The app can't reproduce it on demand, so two likely causes are removed: a Card's hover text still pending when Esc closes the Board with the pointer on a Card, and the menu bar icon's once-a-minute refresh, which set the icon and its text again even when nothing had changed. Hover texts themselves (MVP 20) work as before.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Closing the Board leaves no Card hover text behind; showing it again brings every hover text back
- [x] The menu bar icon's refresh changes the icon and its hover text only when they differ from what is shown
- [x] Tests still pass; the real MacKanban runs the new build

**Notes from implementing:**
- Christoph remembered a Card's hover text for MacKanban, not "x of y used", so the Esc-with-pointer-on-a-Card path is the more likely cause; the refresh change is a cheap second guard. Neither is confirmed: the symptom can't be triggered by hand.
- 2026-11-14: installed with scripts/install.sh. To be watched in daily use; if a ghost tooltip shows up again, note its text and what was done just before.
