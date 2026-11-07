import AppKit

extension NSApplication {
    /// MacKanban to the front because the user asked for one of its windows, from
    /// the menu bar extra, a hotkey or the Dock. Since macOS 14 plain `activate()` is
    /// only a request the system may turn down while another app is in use, and from
    /// the hotkey and the menu bar extra it did (Archive and Settings stayed behind,
    /// spec 0004 ticket 02). The insisting call is deprecated but still works.
    func activateAsAsked() {
        activate(ignoringOtherApps: true)
    }
}
