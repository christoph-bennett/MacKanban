# 03: Restore button in a Discarded Card's sheet

**What to build:** A Discarded Card's read-only sheet in the Archive gets a "Restore" button beside Close, doing what the context menu does (with Triage once 02 is done). Its hover text says the cost beforehand: "Takes up the room of 2 Cards (25 days old)", "Takes up the room of 1 Card" for a fresh one. Return keeps closing the sheet; Restore isn't the default button. The button is always enabled, so a click explains a refusal rather than a greyed-out button hiding why. Done Cards and Sample Cards get no button. VoiceOver reads the button, its cost and the refusal. Spec 0005 stories 3, 16, 17, 30.

**Blocked by:** 01 (Restore from the Archive's context menu)

**Status:** done

- [x] "Restore" beside Close on a Discarded Card's sheet only; none on Done Cards or Discarded Sample Cards
- [x] Clicking it restores the Card and closes the sheet, or shows the refusal (and, once 02 is done, the Triage)
- [x] The hover text shows the cost from the same computation as the gate, singular and plural, after MacKanban's usual 0.3 s
- [x] Return and Esc keep closing the sheet
- [x] VoiceOver reads the button with its cost, and the refusal
- [x] Screenshots light and dark on a sample store; hover with a real mouse; Christoph checks by hand

**Notes from implementing:**
- A Discarded Card's read-only sheet in the Archive gets "Restore" beside Close, unless it's a Sample Card; Done Cards get none. Close stays the default (Return), Esc still closes. A click closes the sheet and runs the same Restore as the context menu: back at once, the refusal, or the Triage on the Board (02).
- The hover text and VoiceOver help say the cost from the same gate as the refusal: "Takes up the room of 2 Cards (34 days old)", "Takes up the room of 1 Card" for a fresh Card, and ", counted in whole Cards as Capacity counts" when rounding makes it a slot more than the Card's age suggests. They're worked out when shown, so they stay right however long the sheet is open.
- Checked on a sample store: the button in light and dark (screenshots), the hover text with a real mouse, VoiceOver's help through the accessibility tree, a click bringing the Triage to the Board, a Done Card's sheet without the button, Esc closing. After the review fixes, the help was read again from the accessibility tree (VLC was in front, so no mouse hover then).
- Review (medium) fixes: the cost worked out on hover rather than when the sheet opens (it went stale, and every sheet paid for it); the button shows even if the cost can't be read, so a click explains; the offer is passed when the sheet is made; one "1 Card / 2 Cards" helper for the hover text, the refusal and the Triage reason; the rounding note in the hover text. Kept: the Restore runs one main-queue turn after the sheet closes (as the Triage's does); a sheet left open while the same Card is restored elsewhere shows the Board's error on a click.
- No new Board tests: the Restore and its gate are 01's and tested there. 139 tests pass.
- Checked by hand by Christoph on 2026-11-08.
