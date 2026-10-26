# Shorter Urgency grace periods

Urgency now starts rising after 12 hours of Card Age in Backlog (was 3 days) and after 4 hours of Column Age in Doing (was 1 day). The full-red points stay at 21 and 7 days. Christoph decided this on 2026-10-26 after his first days of real use: Cards created the day before still looked brand new, so the Board didn't show that anything was aging. This changes the thresholds from ADR 0001. Everything else in that ADR still holds: the thresholds are still constants, not settings.

## Considered Options

- **No grace period at all**: rejected. A Card created a few minutes ago shouldn't already be tinted.
- **Shortening Backlog only**: rejected. A day without touching a Card in Doing is already a sign it's stuck.

## Consequences

Open Cards start costing Capacity sooner, so the same Board ends up with slightly less Capacity than before (a 1-day-old Backlog Card now costs about 0.02, and a 1-day-old Doing Card about 0.12).
