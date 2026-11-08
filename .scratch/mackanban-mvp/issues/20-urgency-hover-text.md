# 20: Hover text on a Card explains its colour

**What to build:** Hovering an Open Card shows a short text that says how old it is and how fast its Column turns red, so a Card in Doing that is redder than an older Card in Backlog makes sense at a glance. Requested 2026-11-08 (Christoph's screenshot: "6d in Doing" was red, "8d old" in Backlog only orange). Follow-up to 05 (Urgency tints); the rules stay as they are (ADR 0001, ADR 0004). Decided the same day: no setting to colour Cards by absolute age instead, since the colour must match what a Card costs in Capacity and what Triage shows.

The text, in English like the rest of the app:
- Doing: "6 days in Doing. Cards in Doing turn fully red after 7 days, in Backlog after 21."
- Backlog: "8 days old. Cards in Backlog turn fully red after 21 days, in Doing after 7."

The age is in whole days ("1 day", "6 days"), in hours under a day ("5 hours", "1 hour") and "less than an hour" under an hour, measured as the age label measures it (Card Age in Backlog, Column Age in Doing). The 7 and 21 days come from the Urgency rules themselves, not a copy. Done Cards have no Urgency and get no hover text.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Hovering a Backlog Card or a Doing Card anywhere but the pencil shows its text after MacKanban's usual 0.3 s hover delay; the pencil keeps its own "Edit (Return)"
- [x] The texts read as above, with the singular and plural forms and the under-a-day and under-an-hour wording
- [x] The text shows also when the age labels are hidden in Settings
- [x] Done Cards show no hover text
- [x] The numbers 7 and 21 come from the Urgency rules, so changing a threshold changes the text
- [x] Board test (or a unit test at the text's seam) for the wording: Backlog and Doing, a day and several days, hours, under an hour
- [ ] Hover checked with a real mouse on a sample store (a Backlog and a Doing Card); Christoph checks by hand (sample store done)

**Notes from implementing:**
- The text is built in the Board's core, next to the Urgency rules, so the 7 and 21 days come from the same thresholds that colour the Card, and the wording is tested at the Board seam: six tests (Doing, Backlog, one day, hours, under an hour, Done). The age is whole days or hours, rounded down; the age label and the hover text now share one measurement, so they can't drift apart.
- Found while checking by hand: no hover text showed at all, not even the pencil's "Edit (Return)" once the Card had been hovered. The Card removed every tracking area on each update, including the one AppKit keeps for the hover text: the same bug the pencil had (fixed 2026-11-07). The Card now removes only its own.
- Checked on a sample store with a real mouse (cliclick): "Draft the talk" (hovered over its title) shows "4 days in Doing. Cards in Doing turn fully red after 7 days, in Backlog after 21.", "Book the dentist" shows "12 days old. Cards in Backlog turn fully red after 21 days, in Doing after 7.", the pencil still shows "Edit (Return)", a Done Card shows nothing. With the age labels hidden: the hover text is set regardless of that setting (by reading the code; not switched by hand).
- Review (medium) fixes: one shared age measurement for the label and the hover text; "after 1 day" singular should a threshold ever be a day; a guard that could never fail folded away. Kept: the wording in the Board's core (so it's testable; the app target has no tests); the Card's hover text restarts when the Board redraws (the minute refresh, a click), as the pencil's always has; the "only my own tracking area" fix copied in two views rather than a shared base class.
- Christoph's hand check still to come.
