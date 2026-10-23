# 04: Settings: WIP Limit and Launch at login

**What to build:** A Settings window (⌘, and from the status item menu) with the WIP Limit (1–5, default 3) and a Launch at login toggle (off by default, via `SMAppService`). Both are stored in `UserDefaults`. Every WIP Limit change also appends a WIP Limit Changed Board Event (from, to) through the Board. Moving a Card into Doing is refused when Doing is at the WIP Limit. Lowering the limit below the current Doing count is allowed: nothing is bounced, new starts are refused, and the Doing header shows "3 / 2" in red. The Doing header always shows count / limit.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] Settings opens with ⌘, and from the status item menu, and shows the WIP Limit and Launch at login
- [ ] Moving into Doing at the WIP Limit is refused with an explanation, records no Moved event, and a Doing → Backlog move is always allowed
- [ ] Lowering the limit below the Doing count keeps the Cards in Doing, shows the header in red, and refuses new starts
- [ ] Every WIP Limit change appends one WIP Limit Changed event with from and to, with no undo
- [ ] Launch at login takes effect without a restart
- [ ] Board tests: WIP Limit enforcement, including after lowering it, and WIP Limit Changed events
