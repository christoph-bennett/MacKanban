# 14: Return in Notes saves the Card

**What to build:** Behaviour change, asked for by Christoph on 2026-11-04: Return in Notes saves the Card, as Return in the Title already does, instead of starting a new line. It presses the sheet's default button: "Add Card" for a new Card, "Save" when editing. Enter on the numeric keypad does the same. With an empty Title nothing happens, as with the disabled button. A new line in Notes is typed with ⇧Return or ⌥Return (the usual Mac defaults when Return does something else).

This reverses ticket 06's "Return in the notes field starts a new line". Add a dated note to ticket 06 and to the spec where the Card sheet's keys are described.

**Blocked by:** none

**Status:** done

- [x] New Card: Return (and keypad Enter) in Notes adds the Card and closes the sheet
- [x] Edit: Return (and keypad Enter) in Notes saves and closes the sheet
- [x] With an empty Title, Return in Notes does nothing and the sheet stays open
- [x] ⇧Return and ⌥Return in Notes insert a new line, in both sheets
- [x] Return in the Title still saves; Return in a read-only Done or Discarded Card's sheet still closes it
- [x] Ticket 06 and the spec have a dated note about the change

**Notes from implementing (2026-11-04):**
- The notes field handles Return before the sheet's default button does: plain Return or keypad Enter calls the sheet's save, which does nothing with an empty title (a disabled button would otherwise let Return through as a new line). ⇧Return and ⌥Return insert a new line; other modifiers (⌘Return, ⌃Return) go on as before. A read-only sheet's notes aren't editable, so Return there still presses Close.
- The spec doesn't describe the Card sheet's keys, so it has no note to change; ticket 06 has the dated note.
- Checked with synthesized key events (the window's key equivalents first, as AppKit does) in New Card and Edit: Return and keypad Enter with an empty title leave the sheet and Notes as they were; ⇧Return and ⌥Return add a line; Return and keypad Enter with a title add or save the Card with its notes and close the sheet; Return in the title still saves; Return in a Done Card's sheet closes it.
- Code review (medium) fixes: while an input method is composing text (Japanese, Pinyin, dead keys), Return goes to it to accept the candidate instead of saving; a held Return (auto-repeat) saves only once; ⇧⌥Return also starts a new line. Skipped: handling `insertNewline:` instead of the key event (the default button takes Return as a key equivalent before the text view's key bindings see it, so the text view has to step in at that stage), `autorecalculatesKeyViewLoop` instead of recalculating in `show(_:)` (the only place that swaps the sheet's content), and the title being focused both by `show(_:)` and the child's `viewDidAppear` (older than this change, harmless). The input-method case can't be checked with synthesized events; the rest was rechecked.
- Checked by hand by Christoph on 2026-11-05.
