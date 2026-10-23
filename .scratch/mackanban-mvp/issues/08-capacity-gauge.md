# 08: Capacity and the Capacity gauge

**What to build:** Board queries return Throughput (Cards that entered Done in the last 14 days; Discarded Cards don't count) and Capacity = 5 + Throughput − Σ Urgency of all Open Cards, rounded down, capped at 20, no floor (ADR 0001), together with its breakdown. A gauge next to the New Card button shows used and total Capacity ("5 of 8") and shifts toward red as free slots run out. Hovering or clicking it explains the breakdown (base 5, +Throughput, −aging, e.g. "−2.4 from aging Cards"). It updates with the minute refresh.

**Blocked by:** 05, 06

**Status:** ready-for-agent

- [ ] The gauge shows Open Cards against Capacity and turns red as free slots run out
- [ ] The breakdown shows base, +Throughput and −aging with one decimal place
- [ ] Capacity can drop over time with no user action, and the gauge reflects it within a minute
- [ ] Board tests: an empty Board has Capacity 5. Throughput counts only the last 14 days (4 recent and 1 at 15 days gives 4). Urgencies 1, 0.5 and 0.4 with Throughput 2 give Capacity 5. Capped at 20, can reach 0 or below. A Discarded Card adds no Throughput and no Urgency
