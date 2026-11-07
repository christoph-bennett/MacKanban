# 06: Age label on Done Cards

**What to build:** Asked for by Christoph on 2026-11-07 (follow-up to spec 0003). Doing Cards show how long they've been in Doing ("4d in Doing"); Done Cards show nothing. Done Cards now show how long they've been in Done ("2d in Done"), in the same place and style, under the same "Show ages on Cards" setting. It's a label only: Done Cards keep no tint, since Urgency doesn't apply to them (ADR 0001). With the Archive Delay it also shows how soon a Card leaves the Board.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] A Done Card's age is the time since it entered Done (its current Done visit), from the Board's state like the other ages
- [x] Done Cards show "<age> in Done" with the same formatting as Doing's label ("2h in Done", "3d in Done"); hidden when "Show ages on Cards" is off, as for the other Columns
- [x] No tint and no Urgency for Done Cards; Capacity unchanged
- [x] Sample Cards in Done show "Sample" with their age, as Sample Cards in the other Columns do (the Card view builds that line the same way for every Column; not screenshotted)
- [x] VoiceOver reads the age as for Doing Cards
- [x] The label updates with the minute refresh
- [x] Board test: a Done Card's age is the time since it entered Done (not its Card Age), and its Urgency stays 0
- [x] Screenshot of Done with ages on a sample store

**Notes from implementing:**
- Board: a Done Card's `age` is the time since it entered Done (its one Done visit; nothing leaves Done), Column Age as for Doing. Its Urgency is pinned to 0 for Done explicitly (ADR 0001), not just through Urgency having no ramp for Done. Done's order is unchanged (newest first). Capacity is unchanged.
- App: the age label reads "<age> in Done" ("2h in Done", "1d in Done") under the same "Show ages on Cards" setting; the Card view, VoiceOver and the Sample line use the age as for the other Columns, and the minute refresh keeps it current.
- Tests: a Done Card's age is its time in Done, not its Card Age, and its Urgency is 0; the old test that pinned "no age in Done" now pins the time in Done. 113 tests pass.
- Spec 0001 story 20: a dated note. GLOSSARY unchanged (Column Age already covers Done).
- Review (medium) fixes: two doc comments that still said "none in Done"; Done's Urgency pinned explicitly; the Done time computed once; the spec note.
- Checked by screenshot on a sample store: Done shows "2h in Done" and "1d in Done" with no tint; VoiceOver reads "Finished chore 29, 2h in Done"; the Capacity gauge unchanged at "8 of 13".
- Checked by hand by Christoph on 2026-11-07.
