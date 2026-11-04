# 14: Return in Notes saves the Card

**What to build:** Behaviour change, asked for by Christoph on 2026-11-04: Return in Notes saves the Card, as Return in the Title already does, instead of starting a new line. It presses the sheet's default button: "Add Card" for a new Card, "Save" when editing. Enter on the numeric keypad does the same. With an empty Title nothing happens, as with the disabled button. A new line in Notes is typed with ⇧Return or ⌥Return (the usual Mac defaults when Return does something else).

This reverses ticket 06's "Return in the notes field starts a new line". Add a dated note to ticket 06 and to the spec where the Card sheet's keys are described.

**Blocked by:** none

**Status:** ready-for-agent

- [ ] New Card: Return (and keypad Enter) in Notes adds the Card and closes the sheet
- [ ] Edit: Return (and keypad Enter) in Notes saves and closes the sheet
- [ ] With an empty Title, Return in Notes does nothing and the sheet stays open
- [ ] ⇧Return and ⌥Return in Notes insert a new line, in both sheets
- [ ] Return in the Title still saves; Return in a read-only Done or Discarded Card's sheet still closes it
- [ ] Ticket 06 and the spec have a dated note about the change
