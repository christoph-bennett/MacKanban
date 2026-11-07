# Spec 0002 — Show-Board hotkey

Status: ready-for-agent

Vocabulary follows [GLOSSARY.md](../../GLOSSARY.md). Respects [ADR 0006](../adr/0006-keyboardshortcuts-for-the-hotkey.md). Designed with Christoph on 2026-11-05; it reshapes the BACKLOG item "Global New Card hotkey": showing the Board comes first, a New Card hotkey stays in Later.

## Problem Statement

To look at the Board while I work in another app, I have to find MacKanban in the Dock, ⌘Tab to it or open it from the menu bar extra. That's enough friction that I don't glance at the Board as often as I should, and its whole point is that aging work stays in sight.

## Solution

A global hotkey, ⌃⌥K by default, brings the Board window to the front from any app. Pressed again while the Board is in front, it closes the Board like Esc and hands me back to the app I came from. Settings get tabs like MacJot's: General (what Settings holds today) and Shortcuts, where I can record another combination, clear it or restore the default.

## User Stories

1. As a user, I want a global hotkey that brings the Board window to the front from any app, so that a look at the Board is one key away.
2. As a user, I want the hotkey to open the Board window when it's closed, show it when MacKanban is hidden, and bring it forward when it's behind other windows, so that it always ends with the Board in front.
3. As a user, I want the hotkey to work when MacKanban isn't the active app, including while only the menu bar extra is showing, so that I don't have to switch first.
4. As a user, I want the hotkey, pressed while the Board window is in front and active, to close it just as Esc does, handing me back to the app I came from unless another MacKanban window is still open, so that the same key takes me there and back.
5. As a user, I want Esc to keep working as it does (story 54), so that nothing I've learned changes.
6. As a user, I want the default hotkey to be ⌃⌥K, so that it sits beside MacJot's ⌃⌥N and ⌃⌥F and works without setting anything up.
7. As a user, I want the hotkey to show the Board even while a sheet is open on it (it just comes to the front with the sheet), so that the hotkey never loses what I was typing.
8. As a user, I want the hotkey, while a sheet is open on the Board in front, to leave the Board where it is rather than close it, so that a half-written Card isn't hidden away.
9. As a user, I want Settings to have tabs, General and Shortcuts, switched from the toolbar as in MacJot, so that settings stay findable as they grow.
10. As a user, I want General to hold what Settings holds today (WIP Limit, Show ages on Cards, Launch at login), unchanged, so that nothing moves for me except into a tab.
11. As a user, I want the Shortcuts tab to show a recorder for the show-Board hotkey, labelled e.g. "Show Board", with its text centred as in MacJot, so that I can see and change the combination.
12. As a user, I want to record a new combination by clicking the recorder and pressing it, so that I can pick one that suits me.
13. As a user, I want to clear the hotkey, so that MacKanban takes no global key when I don't want one.
14. As a user, I want a Restore Default button that sets ⌃⌥K again, so that I can undo my experiments.
15. As a user, I want the recorder to refuse combinations MacKanban's own menus use (⌘N, ⌘W, ⌘0, ⌘⇧A, ⌘→, ⌘←, ⌘⌫, ⌘, and the rest), with the reason, so that the hotkey can't shadow a menu command.
16. As a user, I want the recorder to warn about combinations macOS itself uses, so that I don't break a system shortcut.
17. As a user, I want the recorder to refuse a combination another app holds, saying so ("Another app may be using it"), and keep the previous hotkey, so that I don't end up with a hotkey that silently does nothing.
18. As a user, I want the Shortcuts tab to say when the saved hotkey couldn't be registered at launch because another app holds it, until I record or restore one, so that I know why it doesn't work.
19. As a user, I want the hotkey and my changes to it to survive quitting and relaunching MacKanban, so that I set it once.
20. As a user, I want the hotkey to work only while MacKanban runs, with Launch at login as the way to have it from startup, so that nothing runs in the background without the app.
21. As a user, I want a MacKanban started on a sample store (for screenshots) not to register the hotkey, with a note in the Shortcuts tab, so that it doesn't take ⌃⌥K from my real MacKanban.
22. As a user, I want the Shortcuts tab to be usable with the keyboard and VoiceOver (the recorder and button labelled), as the rest of Settings is.

## Implementation Decisions

- **Dependency:** MacJot's vendored KeyboardShortcuts 3.1.0 is copied into this repository's vendor folder with its README, licence and patch markers (ADR 0006); the package manifest refers to it by path, and only the app target depends on it. KanbanCore stays free of it.
- **Bundle:** the bundle script copies the package's resource bundle into the app, as MacJot's does.
- **The hotkey:** one KeyboardShortcuts name, stored under its own key in the standard defaults, with ⌃⌥K as its initial shortcut. Registered at launch, except in a sample-store instance. Its key-down handler is the toggle below.
- **Toggle:** if the Board window is visible, MacKanban is active, the Board window is the key window and no sheet is attached, the hotkey closes it through the same path as Esc (close, then hide MacKanban unless another MacKanban window is open). Otherwise it activates MacKanban and shows the Board window as the existing "show Board" command does (Window menu, menu bar extra). The Esc logic is shared, not copied.
- **Settings window:** stays AppKit (the WIP Limit goes through the Board). It gains a toolbar with a centred segmented switcher between General and Shortcuts, modelled on MacJot's, and resizes to the selected tab. The window title follows the tab. The existing pane becomes General unchanged; the "one pane" note from the HIG audit (finding 6) no longer applies.
- **Shortcuts tab:** AppKit, using the package's AppKit recorder (its patched version centres the text). Before a recorded combination is saved, MacKanban tries a short system registration; if it fails, the recorder rejects it with "MacKanban can't use this combination. Another app may be using it." and the previous one stays. Combinations in the main menu and those macOS uses are handled by the package. A "Restore Default" button resets to ⌃⌥K (if another app holds ⌃⌥K, it says so and keeps the current one). A note line shows "couldn't be registered" from launch until the hotkey is recorded or restored, and the sample-store note in a sample instance.
- **Menus:** no menu item shows the hotkey; the Window menu's Board item keeps ⌘0.

## Testing Decisions

- No new automated seam (agreed with Christoph on 2026-11-05). KanbanCore and its Board-seam tests are untouched; the feature is AppKit behaviour, system hotkey registration and a Settings tab. With one hotkey there's no conflict logic of MacKanban's own to test, unlike MacJot's two-hotkey `HotkeyCheck`.
- Verified with TEMP hooks in a sample-store instance (calling the hotkey's handler directly: Board closed, hidden, behind another window, in front, in front with a sheet), screenshots of both Settings tabs, and Christoph's check by hand with the real hotkey.
- The full test suite still runs before committing; the existing tests must stay green.

## Out of Scope

- A global New Card hotkey and a quick-add panel (stays in BACKLOG Later).
- Other hotkeys (Archive, moving Cards).
- Showing the hotkey in a menu.
- Detecting combinations another app registered without holding them exclusively (not possible; ADR 0006).

## Further Notes

- Spec 0001 listed "Global hotkey" as out of scope and said "no third-party dependencies"; both are amended by this spec and ADR 0006 (dated notes there).
- After building, Christoph's MacJot and MacKanban both register a global hotkey; ⌃⌥K doesn't collide with MacJot's ⌃⌥N and ⌃⌥F.
- 2026-11-07: a global New Card hotkey was added after all (MVP ticket 17), as a second recorder below Show Board, default ⌃⌥⇧K. It brings the Board forward with the New Card sheet, as ⌘N opens it; still no quick-add panel. The two hotkeys refuse each other's combination.
