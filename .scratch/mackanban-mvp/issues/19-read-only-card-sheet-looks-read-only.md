# 19: A read-only Card looks read-only

**What to build:** Asked for by Christoph on 2026-11-07. A Card opened read-only (a Done Card from the Board with Open, or any Card from the Archive) shows its title and notes in the same bordered text fields as the edit sheet, so nothing says it can't be changed. Following Apple's HIG (text people can't edit is shown as a label, not a text field; dimmed "disabled" fields mean "unavailable right now" and hurt legibility), the read-only sheet shows:

- the title as bold text and the notes as plain wrapping text, without borders or field backgrounds; both still selectable, so they can be copied
- a status line under the heading that says why it can't be changed: "Done on 4 Nov 2026" for a Done Card on the Board, "Done on 4 Nov 2026 · Archived" for an archived Done Card, "Discarded on 6 Nov 2026" for a Discarded Card, with a small SF Symbol before it (e.g. `checkmark.circle` for Done, `archivebox` for archived, `xmark.circle` for Discarded)
- only the Close button, as today (Return and Esc close it)

The edit sheet (Backlog and Doing) doesn't change. Sample Cards still don't open.

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] Read-only title and notes are labels (selectable, not editable, no bezel or background); the edit sheet keeps its fields
- [ ] Long notes wrap and scroll within the sheet; an empty note shows nothing (or a quiet "No notes")
- [ ] The status line shows the right wording and date for a Done Card on the Board, an archived Done Card and a Discarded Card (dates in the user's locale, as elsewhere)
- [ ] The heading stays "Done Card" / "Discarded Card"; Close, Return and Esc close the sheet
- [ ] VoiceOver reads the heading, the status line, the title and the notes as text, not as text fields
- [ ] Readable in light and dark mode
- [ ] Checked by screenshot on a sample store: a Done Card from the Board, an archived Done Card, a Discarded Card, the edit sheet unchanged; Christoph checks by hand
