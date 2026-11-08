# 19: A read-only Card looks read-only

**What to build:** Asked for by Christoph on 2026-11-07. A Card opened read-only (a Done Card from the Board with Open, or any Card from the Archive) shows its title and notes in the same bordered text fields as the edit sheet, so nothing says it can't be changed. Following Apple's HIG (text people can't edit is shown as a label, not a text field; dimmed "disabled" fields mean "unavailable right now" and hurt legibility), the read-only sheet shows:

- the title as bold text and the notes as plain wrapping text, without borders or field backgrounds; both still selectable, so they can be copied
- a status line under the heading that says why it can't be changed: "Done on 4 Nov 2026" for a Done Card on the Board, "Done on 4 Nov 2026 · Archived" for an archived Done Card, "Discarded on 6 Nov 2026" for a Discarded Card, with a small SF Symbol before it (e.g. `checkmark.circle` for Done, `archivebox` for archived, `xmark.circle` for Discarded)
- only the Close button, as today (Return and Esc close it)

The edit sheet (Backlog and Doing) doesn't change. Sample Cards still don't open.

**Blocked by:** None (can start immediately)

**Status:** done

- [x] Read-only title and notes are labels (selectable, not editable, no bezel or background); the edit sheet keeps its fields
- [x] Long notes wrap and scroll within the sheet; an empty note shows nothing (or a quiet "No notes")
- [x] The status line shows the right wording and date for a Done Card on the Board, an archived Done Card and a Discarded Card (dates in the user's locale, as elsewhere)
- [x] The heading stays "Done Card" / "Discarded Card"; Close, Return and Esc close the sheet
- [x] VoiceOver reads the heading, the status line, the title and the notes as text, not as text fields
- [x] Readable in light and dark mode
- [x] Checked by screenshot on a sample store: a Done Card from the Board, an archived Done Card, a Discarded Card, the edit sheet unchanged; Christoph checks by hand

**Notes from implementing:**
- The Board now tells a Done Card when it entered Done (two Board tests); an archived Card's date is its Archive "Ended". The sheet's modes say which line to show: Done on the Board, Done and archived, Discarded.
- Read-only sheet: the status line (secondary colour, symbol before it), the title in bold body text and the notes as selectable body text without border or background. The notes are as tall as their text up to 240 pt, then they scroll; empty notes show a quiet "No notes". The "Title" and "Notes" labels are only on the edit sheet: in bold and in plain text, the two read for what they are.
- Dates use the abbreviated date style, as the Archive's Created column ("5. Nov 2026" in Christoph's locale).
- VoiceOver (checked through System Events): heading, status line, title and notes are static text, then Close; the symbol is hidden from VoiceOver, since the text says the same.
- Review fixes: Esc closes the read-only sheet even while the title or notes have focus (a key equivalent on the sheet, as the edit sheet's Cancel button has; checked with the notes focused); the Board passes the Done date explicitly and asserts it's there; one status-line switch instead of several.
- Checked by screenshot on a sample store, light and dark: a Done Card from the Board with long and with no notes, an archived Done Card, a Discarded Card, the edit sheet unchanged. Screenshots taken through temporary launch hooks (not committed) because a full-screen video covered the screen.
- Checked by hand by Christoph on 2026-11-07.
- Checked on 2026-11-08 (open since the hand check: do always-visible scroll bars cut off long notes?): no. On a sample store with "Show scroll bars: Always" for that instance only (launch argument, the system setting untouched), an archived Done Card with twelve long paragraphs: the notes wrap before the scroll bar, which takes its own strip on the right; nothing is hidden under it. With the default setting the notes use the full width. Screenshots via TEMP launch hooks, since removed.
