# 05: Urgency tints and age labels

**What to build:** Every Open Card shows its Urgency. Board queries return each Card with its Urgency (0…1) and the age its label shows. Backlog Cards use Card Age (neutral up to 3 days, full red at 21) and Doing Cards use accumulated Column Age (neutral up to 1 day, full red at 7), with a linear ramp in between (ADR 0001). The Card's background tints from neutral through amber to red, readable in light and dark mode, and the Card shows an age label ("12d" in Backlog, "4d in Doing" in Doing). Done Cards show no tint. The window refreshes once a minute and after every change.

**Blocked by:** 03

**Status:** done

- [x] Board queries expose Urgency and age per Card, computed from the events and never stored
- [x] Tints go smoothly from neutral through amber to red in both light and dark mode
- [x] Age labels appear on every Open Card, and Done Cards have neither a tint nor a label
- [x] The display updates at least once a minute without user action
- [x] Board tests: a Backlog Card 3 days old has Urgency 0, 12 days 0.5 and 30 days 1. A 30-day-old Card 1 day into Doing has Urgency 0. Column Age adds up across visits

**Notes from implementing:**
- Checked by screenshot on a sample Board (`SampleBoard`, see CLAUDE.md) in light mode: neutral, amber and red tints, labels in Backlog and Doing, none in Done. Dark mode checked by hand by Christoph on 2026-10-23.
- The tint mixes the system card colour with amber, then red, resolved for the view's appearance. Background up to 45 % tint, border the full tint colour.
- The minute refresh skips while the window is hidden, while a sheet is up, and while a mouse button is down (so a drag isn't broken).
- `MACKANBAN_STORE` opens another store with its own settings (no Launch at login), for screenshots and trying things by hand.
- Amended on 2026-10-24 at Christoph's request: the age label runs to 10 pt from the right edge (it kept 30 pt for the hover pencil, which sits at the top right, not next to the label; the title and notes still keep that room). A "Show ages on Cards" setting (on by default, ticket 04's Settings window) hides the labels; tints stay, and the accessibility label still includes the age. Checked by screenshot with ages on and off.
- Amended on 2026-10-24 at Christoph's request: a hidden age keeps its line (the label is transparent instead of removed), so switching ages off doesn't make Cards smaller. Checked by screenshot.
- Amended on 2026-10-24 at Christoph's request: the Backlog label reads "12d old" instead of "12d". A Card moved back from Doing showed nearly the same number as its time in Doing (it had spent most of its life there), which read as if the Doing time carried over. The rule is unchanged: Backlog shows Card Age (ADR 0001).
- HIG audit (2026-10-24, `.scratch/hig-audit/`): the age setting moved from Settings to View > Show/Hide Card Ages (finding 5); Cards have 10 pt padding on all sides (finding 2).
