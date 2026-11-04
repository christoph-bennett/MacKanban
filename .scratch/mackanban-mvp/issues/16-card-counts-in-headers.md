# 16: Card count in the Backlog and Done headers

**What to build:** Asked for by Christoph on 2026-11-04. Only Doing shows a count right of its title ("2 / 3"). Backlog and Done show one too: the number of Cards in that Column, the number alone ("5"; "0" when empty), since neither has a limit. (Changed the same day: Backlog shows "count / room", see the notes.) Done counts only the Cards in the Done Column on the Board, not the Archive. Doing stays as it is ("2 / 3", red over the WIP Limit).

The new counts look like Doing's (secondary colour, monospaced digits), update with every change to the Board (new Card, move, Discard, undo, a Done Card leaving for the Archive) and include Sample Cards like any Card on the Board. VoiceOver reads them as e.g. "5 Cards". The Board model isn't involved: the counts are the Cards the Columns already show.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Backlog's header shows the number of Backlog Cards, Done's the number of Cards in the Done Column (Archive not included), both without "/" (changed: Backlog shows "count / room", see the notes)
- [x] An empty Backlog or Done shows "0"
- [x] Doing's count is unchanged, including the red over the WIP Limit
- [x] The counts follow creating, moving, Discarding, undo and Done Cards leaving for the Archive
- [x] Same font and colour as Doing's count; VoiceOver reads e.g. "5 Cards"
- [x] Spec: a new story 56; ticket 03: a dated note

**Notes from implementing (2026-11-04):**
- Every Column already had the count label; Backlog and Done now fill it on each reload with the number of Cards the Column shows (Done's are the ones not yet in the Archive). VoiceOver reads "1 Card" / "n Cards"; Doing's reading is unchanged. Nothing in the Board model changed.
- Checked by screenshot: a sample Board shows Backlog 5, Doing 3 / 3, Done 8; an empty Board shows 0, 0 / 3, 0. The counts follow changes because they're set in the same reload that redraws the Cards after every change.
- Changed on 2026-11-04 at Christoph's request, after seeing it: Backlog shows "count / room", where room is the Capacity minus the Cards in Doing ("5 / 10" with Capacity 13 and 3 in Doing), because the Capacity limits Backlog too. There is no Backlog limit of its own: the room moves when a Card moves between Backlog and Doing. The room comes from a new Board query (`roomForBacklog` on the Board's state; tested in `CapacityTests`, including that it never goes below 0, since the Capacity has no floor). It's never red: over it, creating is blocked and the Capacity gauge says so. A display only, not a new rule (ADR 0001). VoiceOver reads "5 of 10 Cards". Checked by screenshot: sample Board 5 / 10, 3 / 3, 8; empty Board 0 / 5, 0 / 3, 0.
- Code review (medium) on the first version: no bug. Applied: one loop over the Columns, `isWarning` required. Skipped: VoiceOver possibly reading the count's value besides its label (unverifiable here, and Doing's count has worked that way since ticket 04); a test for the header wording (UI text; the rule behind Backlog's number is tested at the Board); Doing's VoiceOver wording (unchanged by the ticket).
