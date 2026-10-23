import AppKit
import KanbanCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var board: BoardWindowController?
    private var settings: SettingsWindowController?
    private var terminationSignal: DispatchSourceSignal?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // A store other than the real one gets its own settings, so trying things
        // on a sample Board can't change the real WIP Limit.
        let isRealStore = Self.storeOverride == nil
        let defaults = isRealStore ? UserDefaults.standard : UserDefaults(suiteName: "com.onethingwell.mackanban.sample")!
        defaults.register(defaults: [SettingsWindowController.wipLimitKey: Board.defaultWIPLimit])
        do {
            let model = try Board(storeURL: Self.storeURL, wipLimit: defaults.integer(forKey: SettingsWindowController.wipLimitKey))
            let board = BoardWindowController(board: model)
            let settings = SettingsWindowController(board: model, defaults: defaults, offersLaunchAtLogin: isRealStore)
            settings.onWIPLimitChange = { [weak board] in board?.reload() }
            self.board = board
            self.settings = settings
        } catch {
            NSApp.activate()
            let alert = NSAlert(error: error)
            alert.messageText = "MacKanban can't open its Board."
            alert.informativeText = "\(error.localizedDescription)\n\nThe store is \(Self.storeURL.path)."
            alert.runModal()
            NSApp.terminate(nil)
            return
        }
        NSApp.mainMenu = MainMenu.make(appDelegate: self)
        statusItem = makeStatusItem()
        quitNormallyOnTerminationSignal()
        showBoard()
        NSApp.activate()
    }

    /// The menu bar extra keeps MacKanban useful without its window.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    /// Clicking the Dock icon with the Board window closed brings it back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showBoard() }
        return true
    }

    /// `~/Library/Application Support/MacKanban/Board.sqlite` (ADR 0002), unless
    /// `MACKANBAN_STORE` names another file (screenshots, trying things by hand).
    private static var storeURL: URL {
        storeOverride ?? URL.applicationSupportDirectory.appending(components: "MacKanban", "Board.sqlite")
    }

    /// An app opened from Finder or `open` runs in `/`, so a relative path would
    /// point somewhere unexpected; `~` is expanded, other relative paths are refused.
    private static var storeOverride: URL? {
        guard let path = ProcessInfo.processInfo.environment["MACKANBAN_STORE"], !path.isEmpty else { return nil }
        let expanded = (path as NSString).expandingTildeInPath
        guard expanded.hasPrefix("/") else {
            NSLog("MacKanban: MACKANBAN_STORE must be an absolute path, got \(path)")
            return URL(fileURLWithPath: "/nonexistent/\(path)")  // fails to open, with the alert explaining
        }
        return URL(fileURLWithPath: expanded)
    }

    @objc func newCard() {
        showBoard()
        board?.newCard(nil)
    }

    @objc func showSettings() {
        settings?.showWindow(nil)
    }

    @objc func showBoard() {
        guard let board else { return }  // the store didn't open and MacKanban is quitting
        board.showWindow(nil)
        board.window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let image = NSImage(systemSymbolName: "rectangle.split.3x1", accessibilityDescription: "MacKanban")
        image?.isTemplate = true
        item.button?.image = image

        let menu = NSMenu()
        menu.addItem(withTitle: "Open Board", action: #selector(showBoard), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit MacKanban", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        item.menu = menu
        return item
    }

    /// `kill`/`pkill` (e.g. scripts/install.sh) send SIGTERM, which would end
    /// MacKanban on the spot; quit normally instead, so pending saves finish.
    private func quitNormallyOnTerminationSignal() {
        signal(SIGTERM, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        source.setEventHandler { NSApp.terminate(nil) }
        source.resume()
        terminationSignal = source
    }
}
