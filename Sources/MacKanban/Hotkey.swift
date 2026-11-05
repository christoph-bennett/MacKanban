import KeyboardShortcuts

/// The show-Board hotkey as KeyboardShortcuts stores and registers it (ADR 0006).
/// ⌃⌥K is stored the first time the name is used; Settings can change it (ticket 02).
extension KeyboardShortcuts.Name {
    static let showBoard = Self("showBoardHotkey", initial: .init(.k, modifiers: [.control, .option]))
}
