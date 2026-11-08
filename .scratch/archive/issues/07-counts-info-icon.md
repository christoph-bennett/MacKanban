# 07: Info icon beside "Counts"

**What to build:** In the Archive's Done section a small ⓘ sits beside the "Counts" column title. Hovering it shows, in plain words: "Done or Archived Cards each give you room for one more Card, for 14 days after they moved to Done. The bar shows how much of that time is left. After that, the Card stays here but no longer gives you room." Requested 2026-11-07 (BACKLOG); follow-up to ticket 05 (Counts column), spec 0003 stories 32–34. The 14 days are Capacity's Throughput window (ADR 0001), so the text names the same number the bars drain over. The icon is required; showing the text on the column title alone, without a visible ⓘ, doesn't count (decided by Christoph on 2026-11-08).

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] The ⓘ sits beside "Counts" in the Done section's column header, sized and coloured like a secondary header detail, in light and dark
- [ ] Hovering the ⓘ shows the text above, word for word, after MacKanban's usual 0.3 s hover delay
- [ ] VoiceOver reads the explanation for the ⓘ
- [ ] The Counts column keeps its width, the other column titles are unchanged, and the Discarded section has no ⓘ (it has no Counts column)
- [ ] The text's "14 days" comes from the same Throughput window as the bars, not a copy
- [ ] Screenshots of the header in light and dark; hover checked with a real mouse on a sample store; Christoph checks by hand
