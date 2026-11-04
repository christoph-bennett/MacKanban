# 16: Card count in the Backlog and Done headers

**What to build:** Asked for by Christoph on 2026-11-04. Only Doing shows a count right of its title ("2 / 3"). Backlog and Done show one too: the number of Cards in that Column, the number alone ("5"; "0" when empty), since neither has a limit. Done counts only the Cards in the Done Column on the Board, not the Archive. Doing stays as it is ("2 / 3", red over the WIP Limit).

The new counts look like Doing's (secondary colour, monospaced digits), update with every change to the Board (new Card, move, Discard, undo, a Done Card leaving for the Archive) and include Sample Cards like any Card on the Board. VoiceOver reads them as e.g. "5 Cards". The Board model isn't involved: the counts are the Cards the Columns already show.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Backlog's header shows the number of Backlog Cards, Done's the number of Cards in the Done Column (Archive not included), both without "/"
- [ ] An empty Backlog or Done shows "0"
- [ ] Doing's count is unchanged, including the red over the WIP Limit
- [ ] The counts follow creating, moving, Discarding, undo and Done Cards leaving for the Archive
- [ ] Same font and colour as Doing's count; VoiceOver reads e.g. "5 Cards"
- [ ] Spec: a new story 56; ticket 03: a dated note
