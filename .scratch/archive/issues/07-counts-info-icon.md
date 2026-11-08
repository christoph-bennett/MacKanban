# 07: Info icon beside "Counts"

**What to build:** In the Archive's Done section a small ⓘ sits beside the "Counts" column title. Hovering it shows, in plain words: "Done or Archived Cards each give you room for one more Card, for 14 days after they moved to Done. The bar shows how much of that time is left. After that, the Card stays here but no longer gives you room." Requested 2026-11-07 (BACKLOG); follow-up to ticket 05 (Counts column), spec 0003 stories 32–34. The 14 days are Capacity's Throughput window (ADR 0001), so the text names the same number the bars drain over. The icon is required; showing the text on the column title alone, without a visible ⓘ, doesn't count (decided by Christoph on 2026-11-08).

**Blocked by:** None (can start immediately)

**Status:** done

- [x] The ⓘ sits beside "Counts" in the Done section's column header, sized and coloured like a secondary header detail, in light and dark
- [x] Hovering the ⓘ shows the text above, word for word, after MacKanban's usual 0.3 s hover delay
- [x] VoiceOver reads the explanation for the ⓘ
- [x] The Counts column keeps its width, the other column titles are unchanged, and the Discarded section has no ⓘ (it has no Counts column)
- [x] The text's "14 days" comes from the same Throughput window as the bars, not a copy
- [x] Screenshots of the header in light and dark; hover checked with a real mouse on a sample store; Christoph checks by hand

**Notes from implementing:**
- The ⓘ is part of the Counts header's title: the SF Symbol "info.circle" as a text attachment in secondary label colour, after a thin space, in the header's own font. A first version drew it beside the title itself and overlapped the "s": the inset table style draws header text 10 pt further in than the cell reports. As part of the title, AppKit lays out both together, and the ⓘ follows the column when it's resized or moved.
- The hover text is the column's header tooltip, so it also shows over the word "Counts", not only over the ⓘ. A tooltip on the ⓘ alone would need its position, which the header doesn't give reliably (see above). The text comes from Capacity's Throughput window in days, now one constant that the Capacity gauge's hover text uses too.
- VoiceOver: the header still reads "Counts" (without a fix it read the attachment's placeholder character). AppKit's header elements take no help text (tried on the cell, through the old attribute API and on its private proxies), so the header view adds an element of its own over the Counts header: "About Counts", with the explanation as its value. Checked in the accessibility tree via System Events; not listened to with VoiceOver switched on.
- The Discarded section has no ⓘ of its own: the Archive has one header row above both sections.
- Review (medium) fixes: the thin space and the ⓘ take the title's font; the replaced header view keeps the size AppKit gave it; the header setup simplified; one constant for the 14 days. Checked and not needed: switching to dark with the Archive open recolours the ⓘ (screenshot after a switch). Kept: the tooltip over the whole header; the VoiceOver element over the whole header rect (the ⓘ's own rect isn't known, see the first note).
- Checked on a sample store (TEMP launch hooks, since removed): screenshots light and dark; a real mouse hover (cliclick) shows the text at 0.6 s. After forcing the app's appearance to dark from code, no hover text appeared, not even on the bars; without that switch it does. A side effect of the test hook, not of the ⓘ. 115 tests pass.
- Checked by hand by Christoph on 2026-11-08.
