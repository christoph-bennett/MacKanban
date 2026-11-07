import AppKit
import Carbon.HIToolbox
import KeyboardShortcuts

/// The global hotkeys as KeyboardShortcuts stores and registers them (ADR 0006).
/// Each default is stored the first time its name is used; Settings > Shortcuts changes it.
extension KeyboardShortcuts.Name {
    static let showBoard = Self("showBoardHotkey", initial: .init(.k, modifiers: [.control, .option]))
    /// MVP ticket 17: ⌃⌥⇧K, clear of Show Board's ⌃⌥K and MacJot's ⌃⌥N and ⌃⌥F.
    static let newCard = Self("newCardHotkey", initial: .init(.k, modifiers: [.control, .option, .shift]))
}

/// What MacKanban adds to the package for its hotkeys (spec 0002, MVP ticket 17),
/// as in MacJot: telling when another app holds a combination, which the package
/// would otherwise drop without a word, and keeping the two hotkeys apart.
@MainActor
struct Hotkey {
    static let showBoard = Hotkey(name: .showBoard, title: "Show Board")
    static let newCard = Hotkey(name: .newCard, title: "New Card")
    static let all = [showBoard, newCard]

    let name: KeyboardShortcuts.Name
    /// As Settings labels it.
    let title: String

    /// The other hotkeys, whose combinations this one can't take.
    private var others: [Hotkey] { Self.all.filter { $0.name != name } }

    /// The other hotkey that has `shortcut`, if one does.
    private func otherHolding(_ shortcut: KeyboardShortcuts.Shortcut) -> Hotkey? {
        others.first { KeyboardShortcuts.getShortcut(for: $0.name) == shortcut }
    }

    /// Names whose saved combination couldn't be registered at launch because another
    /// app holds it. Shown in Settings until the hotkey is recorded or restored.
    private static var unavailable: Set<KeyboardShortcuts.Name> = []

    var isUnavailable: Bool {
        get { Self.unavailable.contains(name) }
        nonmutating set {
            if newValue { Self.unavailable.insert(name) } else { Self.unavailable.remove(name) }
        }
    }

    /// As menus show it, e.g. `⌃⌥K`, for the current keyboard layout.
    var defaultDisplayString: String {
        name.initialShortcut?.description ?? ""
    }

    /// Before registering at launch: notes a combination another app holds. One
    /// that an earlier hotkey already has (a default stored on upgrade, the same as
    /// a combination recorded before) is cleared, so the two never share it.
    func checkAvailableBeforeRegistering() {
        guard let shortcut = KeyboardShortcuts.getShortcut(for: name) else { return }
        if let earlier = Self.all.prefix(while: { $0.name != name }).first(where: { KeyboardShortcuts.getShortcut(for: $0.name) == shortcut }) {
            KeyboardShortcuts.setShortcut(nil, for: name)
            NSLog("MacKanban: cleared the \(title) hotkey \(shortcut); it's the \(earlier.title) hotkey")
            return
        }
        guard !Self.canRegister(shortcut) else { return }
        isUnavailable = true
        NSLog("MacKanban: couldn't register the \(title) hotkey \(shortcut); another app holds it")
    }

    /// Why the recorder must refuse `shortcut`, or nil. The package itself refuses
    /// combinations in MacKanban's menus and warns about ones macOS uses. While it
    /// records, this hotkey is paused, so re-recording its current one passes; the
    /// other hotkeys' are checked first, as MacKanban itself holds them.
    func problem(recording shortcut: KeyboardShortcuts.Shortcut) -> String? {
        if let other = otherHolding(shortcut) {
            return "This is already the \(other.title) hotkey."
        }
        return Self.canRegister(shortcut) ? nil : "MacKanban can’t use this combination. Another app may be using it."
    }

    /// Why Restore Default can't set the default again, or nil after setting it.
    /// The current hotkey stays when it can't.
    func restoreDefault() -> String? {
        guard let initial = name.initialShortcut else { return nil }
        if let other = otherHolding(initial) {
            return "\(defaultDisplayString) is the \(other.title) hotkey."
        }
        // Already the default and registered: MacKanban's own registration would make
        // the probe fail. Already the default but unavailable: another app may still hold it.
        let holdsIt = KeyboardShortcuts.getShortcut(for: name) == initial && !isUnavailable
        if !holdsIt, !Self.canRegister(initial) { return "\(defaultDisplayString) is in use by another app." }
        // Cleared first, so it's registered afresh even when the default was already stored.
        KeyboardShortcuts.setShortcut(nil, for: name)
        KeyboardShortcuts.reset(name)
        isUnavailable = false
        return nil
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
