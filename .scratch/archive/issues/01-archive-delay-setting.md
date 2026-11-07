# 01: Archive Delay setting

**What to build:** How long Done Cards stay on the Board before they go to the Archive on their own, the Archive Delay, becomes my choice under Settings > General: a dropdown like the WIP Limit's with 1, 2, 3, 5 and 7 days, 3 by default (also on the first launch after this update). A change applies at once to every Done Card: shortening it archives older Done Cards straight away, lengthening it brings them back. The fixed 7-day constant goes away. Spec 0003 stories 18–25, 41–43; ADR 0007.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The Board is created with the stored Archive Delay, like the WIP Limit; allowed values 1, 2, 3, 5, 7 days; default 3 days; a stored value outside them becomes the default
- [x] The Board can change the Archive Delay; a change writes no event and applies at once to Board state and the Archive query
- [x] Settings > General has an "Archive Delay:" row with a dropdown ("1 day" … "7 days") and the note "How long Done Cards stay on the Board before they go to the Archive. Archiving early doesn't change Throughput."
- [x] The choice survives relaunching; a sample-store instance keeps its own value, as for the WIP Limit
- [x] A change refreshes the Board window and an open Archive window
- [x] A Done Card leaves the Board within a minute of its Done visit reaching the Archive Delay
- [x] Throughput and Capacity are unchanged by the delay (a Card archived after 3 days still counts until 14 days after it was finished)
- [x] Board tests: default 3 days (visible just before, archived at 3 days); shortening and lengthening the delay archive and bring back Done Cards; out-of-range stored value → default; no event written. The existing 7-day archive tests are rewritten against the configurable delay
- [x] Spec 0001 gets a dated note that stories 15–16 and the Defaults line's "7-day Archive delay" are superseded by spec 0003
- [x] Screenshot of Settings > General on a sample store

**Notes from implementing:**
- The Board holds `archiveDelay` in days, passed in like the WIP Limit; `Board.archiveDelays` is [1, 2, 3, 5, 7], the default 3. `changeArchiveDelay(to:)` refuses a value not on offer (`archiveDelayNotOffered`) and writes no event. The archive rule (`isArchived`) became an instance method reading it; the fixed 7-day constant is gone. Still nothing is recorded when a Card is archived.
- Settings > General: an "Archive Delay:" row under the WIP Limit, a pop-up button ("1 day" … "7 days") with the note from the spec; stored under its own key in the app's defaults (the sample store's suite for a sample instance). A change reloads the Board window, which reloads an open Archive. "Within a minute" comes from the Board's existing minute refresh (ticket 10), unchanged.
- Spec 0001: dated notes on stories 15 and 16; the Defaults line now lists "Archive Delay 3 days" among the defaults instead of the constants.
- Tests: the 7-day test became the 3-day default; new scenarios for a chosen delay (7 days), changing it in both directions at once, no event and unchanged Throughput, the values on offer, an out-of-range stored value, and a refused value. 87 tests pass.
- Review (medium) fixes: the spec 0001 Defaults line no longer calls the delay both a constant and a setting; one `onBoardSettingChange` callback for the WIP Limit and the Archive Delay; the test helper `finish` takes a Board instead of a copied body; both pop-up buttons use item tags; the General grid finds its padded rows and the approval row from their views instead of hard-coded indices. Kept: the alert in `archiveDelayChanged`, unreachable from the menu but consistent with the WIP Limit's.
- Checked by screenshot on a sample store (TEMP hook to open Settings, since removed): Settings > General with the new row; the Board with 3 days (Done shows 2 Cards) and with 7 days stored (Done shows 8), the Capacity unchanged at "8 of 13".
