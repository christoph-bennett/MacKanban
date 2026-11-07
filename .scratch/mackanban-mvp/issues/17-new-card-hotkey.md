# 17: Global hotkey for a New Card

**What to build:** Asked for by Christoph on 2026-11-07 (BACKLOG, moved from Later to MVP). A second global hotkey, beside Show Board (spec 0002), brings the Board to the front from any app and opens the New Card sheet on it, exactly as ⌘N does: through the creation gate, so a blocked attempt is recorded and Triage appears when it would with ⌘N (spec 0001, ADR 0001). No quick-add panel of its own (decided 2026-11-07). Settings > Shortcuts gets a second recorder, "New Card", below "Show Board".

**Blocked by:** None (can start immediately; reuses spec 0002's KeyboardShortcuts setup, ADR 0006)

**Status:** done

- [x] A second KeyboardShortcuts name with its own default combination ⌃⌥⇧K (confirmed by Christoph on 2026-11-07; it doesn't collide with Show Board ⌃⌥K or MacJot's ⌃⌥N and ⌃⌥F), stored like the first
- [x] The hotkey activates MacKanban, shows the Board window (open, unhide or bring forward, as Show Board does) and opens the New Card sheet through the same path as ⌘N
- [x] If a sheet is already open on the Board, the hotkey only brings the Board forward and opens nothing new
- [x] If MacKanban wasn't in front before the hotkey, closing the sheet (saved or cancelled) closes the Board like Esc and hands back to the app Christoph came from; otherwise the Board stays (confirmed by Christoph on 2026-11-07)
- [x] Settings > Shortcuts: a "New Card" recorder below "Show Board", with clear and Restore Default, the same refusals as Show Board's (menu combinations, system combinations, another app holding it) and also refusing Show Board's current combination (and vice versa)
- [x] The "couldn't be registered" note covers either hotkey; a sample-store instance registers neither and says so
- [x] Both hotkeys survive relaunching; MacKanban's menus don't show them
- [x] Spec 0002: a dated note that a New Card hotkey was added (it listed it as out of scope)
- [x] Checked with TEMP hooks on a sample store (Board closed, hidden, behind, in front, with a sheet; a blocked creation), screenshots of the Shortcuts tab light and dark; Christoph checks the real hotkey by hand

**Notes from implementing:**
- One `Hotkey` type for both hotkeys (Show Board, New Card): the launch check, the recorder's refusals, Restore Default and the "another app is using this combination" note work per hotkey. A recorder refuses the other hotkey's combination ("This is already the Show Board hotkey."), and Restore Default refuses a default the other hotkey has. At launch, a combination the Show Board hotkey already has is cleared from New Card (only possible if ⌃⌥⇧K was recorded for Show Board before this version).
- The hotkey runs ⌘N's path (creation gate, Triage, blocked attempt recorded). Whether it came from another app is decided when it's pressed: then the Board closes as with Esc once the New Card sheet is dismissed (saved, cancelled, at Triage or blocked). Hiding MacKanban while the sheet is up doesn't use up the hand-back. A sheet or alert already on the Board: the Board comes forward, nothing new opens.
- Settings > Shortcuts: "New Card" below "Show Board", each with its note, explanation and Restore Default; a sample store shows both as Off with one note. Spec 0002 got a dated note; BACKLOG item marked done.
- Review (medium) fixes: the hand-back hangs on the sheet's dismissal, not on it disappearing (⌘H); the launch check clears a shared combination; Settings finds the note rows from their views instead of row arithmetic; conflicts are checked against all other hotkeys. Kept: deciding "came from another app" when the hotkey is pressed (as the ticket says); a store error while opening shows its alert and leaves the Board in front.
- Checked on sample stores with TEMP hooks (since removed; SIGUSR1 stood in for the key press, AX button presses for clicks): from Terminal with the Board open, Cancel at Triage closes the Board and Terminal is in front again; with the Board closed and MacKanban hidden, Keep, a title and Add Card save the Card and hand back; with MacKanban in front, Cancel leaves the Board; pressed again with a sheet up (also from Terminal), nothing new opens; with the Archive window in front, the Board comes in front of it with the blocked step, and one Creation Blocked event is recorded; hidden and unhidden with the sheet up, Cancel still hands back. Screenshots of the Shortcuts tab in light and dark, with the unavailable note, and the sample-store version.
- Christoph's hand check with the real hotkey still to come. His Show Board hotkey is ⌃⌥⇧⌘K, so ⌃⌥⇧K is free.
