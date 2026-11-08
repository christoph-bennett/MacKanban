# 01: Clearer Capacity line and marked Doing Cards

**What to build:** The menu bar extra's first line says "Capacity: 4 of 16 used", without the aging figure (stories 1–8). Doing Cards show their titles behind a guillemet, with none closing it: » Fix the build script (stories 9–19). Choosing a Card still moves it to Done, and the app's own items stay unmarked. The decoration lives in one place, so that it can change later. Spec 0006; ADR 0001 stays as it is, and the Capacity gauge on the Board keeps its breakdown.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The Capacity line shows the Open Cards and the total with no decimals, also with more Open Cards than Capacity, at zero and below, and at the cap (Board tests)
- [x] A Doing Card's menu title has the guillemet; a title of 50 characters stays whole, and one of 51 is shortened to end in the ellipsis (Board tests)
- [x] Screenshots of the open menu on a sample store, light and dark, with short and long titles and with "Nothing in Doing"
- [x] Choosing a marked Card moves it to Done and ⌘Z undoes it; its hover text is unchanged; the menu items' titles carry the same text in the accessibility tree
- [x] Christoph has seen it and decided: guillemet or quotation marks

**Notes from implementing:**
- The Capacity line and the menu title moved from the menu bar extra to KanbanCore, so that they can be tested; the 9 new tests failed before the change, and all 148 pass after it. The Capacity gauge's VoiceOver label now uses the same line.
- Decided on 2026-11-08: the guillemet stays, after Christoph looked at it on a sample store.
- Read from the accessibility tree of a sample store: the first line and the three marked Cards carry the new text, and the app's own items have no mark. The hover text's code is unchanged.
- Checked on a sample store with real clicks and keys on 2026-11-08, on the installed app: light screenshots with short and long titles and with "Nothing in Doing"; a long title is cut at 50 characters; hovering a Card shows "4d in Doing. Choose to move it to Done."; choosing a Card records one event and takes it off the list; ⌘Z in the Board window takes the event back and returns the Card.
- Dark screenshot on a sample store on 2026-11-08, after Christoph switched the Mac to dark: short and long titles look right. The launch argument `-AppleInterfaceStyle Dark` leaves this menu light, so it takes the whole Mac in dark. "Nothing in Doing" was photographed in light only.
- Checked by hand by Christoph on 2026-11-08: the guillemet on a sample store, and VoiceOver.
- For later UI tests: System Events reported Terminal as frontmost while `lsappinfo front` reported MacKanban, so `lsappinfo` is the check to use. Choosing rows works when the pointer moves there first, with no accessibility queries between the clicks.
- Built and installed on 2026-11-08 with Xcode as the active developer directory.
