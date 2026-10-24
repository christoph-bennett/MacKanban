# 11: Menu bar extra

**What to build:** The status item shows the Board's state and offers everyday actions. Its icon is tinted by the highest Urgency of any Open Card (neutral, amber, red) and switches to a filled variant when Capacity is used up. The menu shows the Capacity line ("5 of 8 used, −2.4 from aging"), the Doing Cards (choosing one moves it to Done, recording a Moved event), **New Card…** (brings the Board window forward and opens the New Card sheet, gate included), **Open Board**, **Settings…** and **Quit**. Both update with the minute refresh.

**Blocked by:** 09

**Status:** done

- [ ] The icon tint follows the highest Urgency and works in a light and dark menu bar
- [ ] The filled variant appears exactly when there are 0 or fewer free slots
- [ ] The menu shows the Capacity line and the Doing Cards, and choosing a Card moves it to Done (undoable with ⌘Z in the Board window)
- [ ] New Card… opens the Board window with the sheet, going through Triage or the block as usual
- [ ] Open Board, Settings… and Quit work

**Notes from implementing:**
- No new Board behaviour: `state()` and `move(_:to:)` already give everything, and the spec lists the menu bar under "Not automated", so this ticket has no new Board tests.
- `StatusItemController` owns the status item. It refreshes once a minute on its own (the Board window skips its refresh while hidden), rebuilds the menu each time it opens, and gets every state the Board window shows (`onStateChange`, which replaced `onCapacityChange`).
- Icon: neutral (template, follows a light or dark menu bar) while no Open Card has Urgency, amber while one is aging, red once one is fully red (the same condition that starts Triage). Filled at 0 or fewer free slots. The menu bar ignores `contentTintColor` on a template image, so the coloured states are a non-template symbol coloured through a palette configuration.
- Choosing a Doing Card goes through the Board view controller's move, so ⌘Z in the Board window undoes it. A refused move shows as its own alert while the Board window is hidden (a sheet on a hidden window would be invisible).
- The menu shows the Card titles (shortened past 50 characters) under a "Doing: choose a Card to move it to Done" header, with the age as tooltip.
- Review (medium) fixes: choosing a Doing Card while a Board sheet is open (which may be about that Card) is refused with a beep and brings the window forward; finishing from the menu leaves the Board's selection alone; an error alert while the window is hidden activates MacKanban first; if the Board can't be read, the icon falls back to the plain one instead of a stale state or none. Skipped: the status timer also running while the window is open (one extra small query a minute keeps the icon independent of the window); the extra reload at startup (cheap, and needed because the window loads before its callback can be set); the coloured icon not inverting while its menu is open (a hand check below).
- Checked by screenshot on sample Boards: the menu, the neutral, red and filled red icons in a light menu bar. Not yet checked by hand: the amber icon, a dark menu bar, choosing a Doing Card and ⌘Z afterwards, New Card… (with Triage and blocked), Open Board, Settings…, Quit, the icon changing within a minute, and how the amber or red icon looks while its menu is open.
