# 11: Menu bar extra

**What to build:** The status item shows the Board's state and offers everyday actions. Its icon is tinted by the highest Urgency of any Open Card (neutral, amber, red) and switches to a filled variant when Capacity is used up. The menu shows the Capacity line ("5 of 8 used, −2.4 from aging"), the Doing Cards (choosing one moves it to Done, recording a Moved event), **New Card…** (brings the Board window forward and opens the New Card sheet, gate included), **Open Board**, **Settings…** and **Quit**. Both update with the minute refresh.

**Blocked by:** 09

**Status:** ready-for-agent

- [ ] The icon tint follows the highest Urgency and works in a light and dark menu bar
- [ ] The filled variant appears exactly when there are 0 or fewer free slots
- [ ] The menu shows the Capacity line and the Doing Cards, and choosing a Card moves it to Done (undoable with ⌘Z in the Board window)
- [ ] New Card… opens the Board window with the sheet, going through Triage or the block as usual
- [ ] Open Board, Settings… and Quit work
