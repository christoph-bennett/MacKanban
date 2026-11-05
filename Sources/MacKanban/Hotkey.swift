import AppKit
import Carbon.HIToolbox
import KeyboardShortcuts

/// The show-Board hotkey as KeyboardShortcuts stores and registers it (ADR 0006).
/// ⌃⌥K is stored the first time the name is used; Settings > Shortcuts changes it.
extension KeyboardShortcuts.Name {
    static let showBoard = Self("showBoardHotkey", initial: .init(.k, modifiers: [.control, .option]))
}

/// What MacKanban adds to the package for its one hotkey (spec 0002), as in
/// MacJot: telling when another app holds the combination, which the package
/// would otherwise drop without a word.
@MainActor
enum ShowBoardHotkey {
    /// The saved combination couldn't be registered at launch because another app
    /// holds it. Shown in Settings until the hotkey is recorded or restored.
    static var isUnavailable = false

    /// As menus show it, e.g. `⌃⌥K`, for the current keyboard layout.
    static var defaultDisplayString: String {
        KeyboardShortcuts.Name.showBoard.initialShortcut?.description ?? ""
    }

    /// Before registering at launch: notes a combination another app holds.
    static func checkAvailableBeforeRegistering() {
        guard let shortcut = KeyboardShortcuts.getShortcut(for: .showBoard), !canRegister(shortcut) else { return }
        isUnavailable = true
        NSLog("MacKanban: couldn't register the show-Board hotkey \(shortcut); another app holds it")
    }

    /// Why the recorder must refuse `shortcut`, or nil. The package itself refuses
    /// combinations in MacKanban's menus and warns about ones macOS uses. While it
    /// records, the hotkey is paused, so re-recording the current one passes.
    static func problem(recording shortcut: KeyboardShortcuts.Shortcut) -> String? {
        canRegister(shortcut) ? nil : "MacKanban can’t use this combination. Another app may be using it."
    }

    /// Sets ⌃⌥K again, unless another app holds it. Returns false then, and the
    /// current hotkey stays.
    static func restoreDefault() -> Bool {
        guard let initial = KeyboardShortcuts.Name.showBoard.initialShortcut else { return true }
        // Already ⌃⌥K and registered: MacKanban's own registration would make the
        // probe fail. Already ⌃⌥K but unavailable: another app may still hold it.
        let holdsIt = KeyboardShortcuts.getShortcut(for: .showBoard) == initial && !isUnavailable
        if !holdsIt, !canRegister(initial) { return false }
        // Cleared first, so it's registered afresh even when ⌃⌥K was already stored.
        KeyboardShortcuts.setShortcut(nil, for: .showBoard)
        KeyboardShortcuts.reset(.showBoard)
        isUnavailable = false
        return true
    }

    /// Registers `shortcut` for a moment; fails if it's registered already, in
    /// MacKanban or exclusively by another app.
    private static func canRegister(_ shortcut: KeyboardShortcuts.Shortcut) -> Bool {
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(shortcut.carbonKeyCode), UInt32(shortcut.carbonModifiers),
            EventHotKeyID(signature: 0x4B414E42, id: 0),  // 'KANB'
            GetApplicationEventTarget(), 0, &ref
        )
        guard status == noErr, let ref else { return false }
        UnregisterEventHotKey(ref)
        return true
    }
}
