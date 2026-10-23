# 05: Urgency tints and age labels

**What to build:** Every Open Card shows its Urgency. Board queries return each Card with its Urgency (0…1) and the age its label shows. Backlog Cards use Card Age (neutral up to 3 days, full red at 21) and Doing Cards use accumulated Column Age (neutral up to 1 day, full red at 7), with a linear ramp in between (ADR 0001). The Card's background tints from neutral through amber to red, readable in light and dark mode, and the Card shows an age label ("12d" in Backlog, "4d in Doing" in Doing). Done Cards show no tint. The window refreshes once a minute and after every change.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] Board queries expose Urgency and age per Card, computed from the events and never stored
- [ ] Tints go smoothly from neutral through amber to red in both light and dark mode
- [ ] Age labels appear on every Open Card, and Done Cards have neither a tint nor a label
- [ ] The display updates at least once a minute without user action
- [ ] Board tests: a Backlog Card 3 days old has Urgency 0, 12 days 0.5 and 30 days 1. A 30-day-old Card 1 day into Doing has Urgency 0. Column Age adds up across visits
