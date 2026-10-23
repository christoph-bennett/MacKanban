import AppKit
import ServiceManagement

/// Opening MacKanban at login, read from the system each time rather than from a
/// stored copy, so a change under System Settings > General > Login Items shows up
/// in MacKanban's Settings. Off by default (spec 0001). Adapted from MacJot.
@MainActor
enum LaunchAtLogin {
    enum State {
        case on, off
        /// Registered, but switched off under "Allow in the Background"; only
        /// the user can switch it on again, in System Settings.
        case needsApproval
        /// Not running as an app bundle (e.g. `swift run`): nothing to register.
        case unavailable
    }

    static var state: State {
        guard isAppBundle else { return .unavailable }
        switch SMAppService.mainApp.status {
        case .enabled: return .on
        case .requiresApproval: return .needsApproval
        default: return .off
        }
    }

    /// A failure is logged and reported as false; `state` then still tells the truth.
    @discardableResult
    static func set(_ on: Bool) -> Bool {
        guard isAppBundle else { return false }
        do {
            if on {
                // Already on: nothing to do. (Unregistering to register afresh would
                // lose a working login item if registering then failed.)
                guard SMAppService.mainApp.status != .enabled else { return true }
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            NSLog("MacKanban: couldn't turn \(on ? "on" : "off") opening at login: \(error)")
            return false
        }
    }

    static func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    private static var isAppBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }
}
