# 03: Restore button in a Discarded Card's sheet

**What to build:** A Discarded Card's read-only sheet in the Archive gets a "Restore" button beside Close, doing what the context menu does (with Triage once 02 is done). Its hover text says the cost beforehand: "Takes up the room of 2 Cards (25 days old)", "Takes up the room of 1 Card" for a fresh one. Return keeps closing the sheet; Restore isn't the default button. The button is always enabled, so a click explains a refusal rather than a greyed-out button hiding why. Done Cards and Sample Cards get no button. VoiceOver reads the button, its cost and the refusal. Spec 0005 stories 3, 16, 17, 30.

**Blocked by:** 01 (Restore from the Archive's context menu)

**Status:** ready-for-agent

- [ ] "Restore" beside Close on a Discarded Card's sheet only; none on Done Cards or Discarded Sample Cards
- [ ] Clicking it restores the Card and closes the sheet, or shows the refusal (and, once 02 is done, the Triage)
- [ ] The hover text shows the cost from the same computation as the gate, singular and plural, after MacKanban's usual 0.3 s
- [ ] Return and Esc keep closing the sheet
- [ ] VoiceOver reads the button with its cost, and the refusal
- [ ] Screenshots light and dark on a sample store; hover with a real mouse; Christoph checks by hand
