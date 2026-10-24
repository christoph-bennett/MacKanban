# 06: Edit and Discard Cards

**What to build:** Editing a Card's title and notes in Backlog and Doing. The Card's text can't be selected (it would get in the way of dragging), so editing starts from an edit button (pencil icon) on the Card, shown only while the pointer is over it (not because the Card is selected; changed after trying it). Double-click and Return on the selected Card do the same. Done Cards are read-only. A committed edit that changes something appends one Edited event, with no content. An edit that changes nothing records no event. Editing never changes either age. Discarding an Open Card (context menu and a keyboard shortcut, e.g. ⌘⌫) removes it from the Board and appends a Discarded event.

**Blocked by:** 02

**Status:** done

- [x] The pencil button, double-click and Return open the edit sheet for Backlog and Doing Cards. Done Cards have no pencil, and double-click opens them read-only
- [x] One Edited event per committed change, none when nothing changed, and no text is stored in the event
- [x] Card Age and Column Age are unchanged by editing
- [x] Discard removes an Open Card from the Board and appends one Discarded event. Done Cards can't be Discarded
- [x] Board tests: Edited events (including none for no change), ages unaffected, Done read-only, Discard and its event

**Notes from implementing:**
- The New Card sheet became the Card sheet: new, edit, and read-only for Done Cards (Esc or Return closes it).
- Return in the notes field starts a new line; Return in the title field saves.
- The Card menu (Edit Card… / Open Card… for Done, Discard Card ⌘⌫, moves) is off while a sheet is up, so shortcuts typed in the sheet can't act on the Card being edited.
- Discard has no confirmation: ⌘Z (ticket 07) makes it reversible. Until 07 lands, a Discard can't be taken back.
- Checked by hand by Christoph on 2026-10-23.
- HIG audit (2026-10-24, `.scratch/hig-audit/`): the hover pencil is a real accessory button (22 × 22 pt, highlight under the pointer, press state); the Card sheet labels Title like Notes, and the notes box has a rounded border.
- Changed on 2026-10-24 at Christoph's request: while the pointer is over a Card, its pencil sits on an opaque chip (the neutral Card colour with 15% accent; 25% under the pointer, 35% pressed) with the pencil in the accent colour. A see-through accent fill was tried first and turned muddy on red Cards. Checked by screenshot in light and dark.
- Changed again on 2026-10-24: the accent chip clashed with aged (red) Cards. The chip is now a see-through neutral shade (black at 9% in light mode, white at about 12% in dark; deeper under the pointer and pressed), so it's a deeper version of each Card's own colour; the pencil uses the text colour. Checked by screenshot on neutral, amber and red Cards in light and dark.
- Fixed on 2026-10-24: on one-line Cards without notes the age sat 4 pt under the pencil chip. The age now keeps at least 8 pt below it (those Cards grow by 4 pt; hidden pencil or not, so hovering doesn't change heights). Checked by screenshot.
