# 06: Edit and Discard Cards

**What to build:** Editing a Card's title and notes in Backlog and Doing (double-click or Return opens the edit sheet). Done Cards are read-only. A committed edit that changes something appends one Edited event, with no content. An edit that changes nothing records no event. Editing never changes either age. Discarding an Open Card (context menu and a keyboard shortcut, e.g. ⌘⌫) removes it from the Board and appends a Discarded event.

**Blocked by:** 02

**Status:** ready-for-agent

- [ ] Title and notes can be edited in Backlog and Doing, and Done Cards open read-only
- [ ] One Edited event per committed change, none when nothing changed, and no text is stored in the event
- [ ] Card Age and Column Age are unchanged by editing
- [ ] Discard removes an Open Card from the Board and appends one Discarded event. Done Cards can't be Discarded
- [ ] Board tests: Edited events (including none for no change), ages unaffected, Done read-only, Discard and its event
