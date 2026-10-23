# 04: Settings: WIP Limit and Launch at login

**What to build:** A Settings window (⌘, and from the status item menu) with the WIP Limit (1–5, default 3) and a Launch at login toggle (off by default, via `SMAppService`). Both are stored in `UserDefaults`. Every WIP Limit change also appends a WIP Limit Changed Board Event (from, to) through the Board. Moving a Card into Doing is refused when Doing is at the WIP Limit. Lowering the limit below the current Doing count is allowed: nothing is bounced, new starts are refused, and the Doing header shows "3 / 2" in red. The Doing header always shows count / limit.

**Blocked by:** 03

**Status:** done

- [x] Settings opens with ⌘, and from the status item menu, and shows the WIP Limit and Launch at login
- [x] Moving into Doing at the WIP Limit is refused with an explanation, records no Moved event, and a Doing → Backlog move is always allowed
- [x] Lowering the limit below the Doing count keeps the Cards in Doing, shows the header in red, and refuses new starts
- [x] Every WIP Limit change appends one WIP Limit Changed event with from and to, with no undo
- [x] Launch at login takes effect without a restart
- [x] Board tests: WIP Limit enforcement, including after lowering it, and WIP Limit Changed events

**Notes from implementing:**
- Settings is AppKit: a WIP Limit change goes through the Board, which records the WIP Limit Changed event.
- A stored WIP Limit outside 1–5 falls back to 3 (Board test).
- Checked by hand by Christoph on 2026-10-23.
- Amended after trying it: over the limit, the whole Doing Column turns red (tinted background and a red outline), not only the count.
- Amended after trying it: dragging a Card over a full Doing turns the Column red (as when over the limit) and refuses the drop, so the Card goes back instead of an alert explaining afterwards. Other refused drops (e.g. Backlog → Done) still drop and explain. The Board has `moveRefusal(_:to:)` for this.
- The red refused drop over a full Doing checked by hand by Christoph on 2026-10-23.
