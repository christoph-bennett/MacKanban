# 06: Age label on Done Cards

**What to build:** Asked for by Christoph on 2026-11-07 (follow-up to spec 0003). Doing Cards show how long they've been in Doing ("4d in Doing"); Done Cards show nothing. Done Cards now show how long they've been in Done ("2d in Done"), in the same place and style, under the same "Show ages on Cards" setting. It's a label only: Done Cards keep no tint, since Urgency doesn't apply to them (ADR 0001). With the Archive Delay it also shows how soon a Card leaves the Board.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] A Done Card's age is the time since it entered Done (its current Done visit), from the Board's state like the other ages
- [ ] Done Cards show "<age> in Done" with the same formatting as Doing's label ("2h in Done", "3d in Done"); hidden when "Show ages on Cards" is off, as for the other Columns
- [ ] No tint and no Urgency for Done Cards; Capacity unchanged
- [ ] Sample Cards in Done show "Sample" with their age, as Sample Cards in the other Columns do
- [ ] VoiceOver reads the age as for Doing Cards
- [ ] The label updates with the minute refresh
- [ ] Board test: a Done Card's age is the time since it entered Done (not its Card Age), and its Urgency stays 0
- [ ] Screenshot of Done with ages on a sample store
