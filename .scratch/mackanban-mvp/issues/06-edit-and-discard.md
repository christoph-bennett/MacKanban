# 06: Edit and Discard Cards

**What to build:** Editing a Card's title and notes in Backlog and Doing. The Card's text can't be selected (it would get in the way of dragging), so editing starts from an edit button (pencil icon) on the Card, shown while the pointer is over it or while it's selected. Double-click and Return on the selected Card do the same. Done Cards are read-only. A committed edit that changes something appends one Edited event, with no content. An edit that changes nothing records no event. Editing never changes either age. Discarding an Open Card (context menu and a keyboard shortcut, e.g. ⌘⌫) removes it from the Board and appends a Discarded event.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] The pencil button, double-click and Return open the edit sheet for Backlog and Doing Cards. Done Cards have no pencil, and double-click opens them read-only
- [ ] One Edited event per committed change, none when nothing changed, and no text is stored in the event
- [ ] Card Age and Column Age are unchanged by editing
- [ ] Discard removes an Open Card from the Board and appends one Discarded event. Done Cards can't be Discarded
- [ ] Board tests: Edited events (including none for no change), ages unaffected, Done read-only, Discard and its event
