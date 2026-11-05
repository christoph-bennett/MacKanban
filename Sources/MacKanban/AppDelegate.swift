import AppKit
import KanbanCore
import KeyboardShortcuts

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: StatusItemController?
    private var board: BoardWindowController?
    private var settings: SettingsWindowController?
    private var archive: ArchiveWindowController?
    private var terminationSignal: DispatchSourceSignal?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // A store other than the real one gets its own settings, so trying things
        // on a sample Board can't change the real WIP Limit.
        let isRealStore = Self.storeOverride == nil
        let defaults = isRealStore ? UserDefaults.standard : UserDefaults(suiteName: "com.onethingwell.mackanban.sample")!
        defaults.register(defaults: [SettingsWindowController.wipLimitKey: Board.defaultWIPLimit,
                                     SettingsWindowController.showsAgesKey: true])
        do {
            let model = try Board(storeURL: Self.storeURL, wipLimit: defaults.integer(forKey: SettingsWindowController.wipLimitKey))
            let board = BoardWindowController(board: model)
            let settings = SettingsWindowController(board: model, defaults: defaults, offersLaunchAtLogin: isRealStore)
            settings.onWIPLimitChange = { [weak board] in board?.reload() }
            board.showsAges = defaults.bool(forKey: SettingsWindowController.showsAgesKey)
            settings.onShowsAgesChange = { [weak board] in board?.showsAges = $0 }
            let statusItem = StatusItemController(board: model)
            statusItem.onNewCard = { [weak self] in self?.newCard() }
            statusItem.onOpenBoard = { [weak self] in self?.showBoard() }
            statusItem.onSettings = { [weak self] in self?.showSettings() }
            statusItem.onFinish = { [weak board] in board?.finish($0) }
            statusItem.onAddSampleCards = { [weak self] in
                self?.showBoard()
                self?.board?.addSampleCards()
            }
            statusItem.onRemoveSampleCards = { [weak self] in
                self?.showBoard()
                self?.board?.removeSampleCards()
            }
            let archive = ArchiveWindowController(board: model)
            board.onStateChange = { [weak statusItem, weak archive] in
                statusItem?.show($0)
                archive?.reload()
            }
            self.archive = archive
            self.board = board
            self.settings = settings
            self.statusItem = statusItem
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
        // A sample store's MacKanban leaves the hotkey to the real one.
        if isRealStore {
            KeyboardShortcuts.onKeyDown(for: .showBoard) { [weak self] in self?.toggleBoard() }
        }
        quitNormallyOnTerminationSignal()
        showBoard()
        NSApp.activate()
        offerSampleCardsOnFirstLaunch(defaults: defaults)
    }

    static let sampleCardsOfferedKey = "sampleCardsOffered"

    /// Once, and only to a Board that never had a Card (ADR 0005). The flag is set
    /// once the offer is shown, whatever the answer, or once the Board turns out to
    /// have Cards, so emptying the Board later never brings the offer back.
    private func offerSampleCardsOnFirstLaunch(defaults: UserDefaults) {
        guard !defaults.bool(forKey: Self.sampleCardsOfferedKey), board?.offerSampleCards() == true else { return }
        defaults.set(true, forKey: Self.sampleCardsOfferedKey)
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

    @objc func showArchive() {
        archive?.showWindow(nil)
    }

    @objc func showSettings() {
        settings?.showWindow(nil)
    }

    /// Every way to it is the user asking for the Board (hotkey, menu bar extra,
    /// Dock, menus), so it insists on activating: since macOS 14, plain `activate()`
    /// is only a request the system may turn down while another app is in use, and
    /// for the hotkey it did. The call is deprecated but still works.
    @objc func showBoard() {
        guard let board else { return }  // the store didn't open and MacKanban is quitting
        board.showWindow(nil)
        board.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// The show-Board hotkey (spec 0002): the Board to the front, or, when it's
    /// already in front with nothing open on it, away again as with Esc. A sheet on
    /// the Board keeps it where it is, so a half-written Card isn't hidden.
    func toggleBoard() {
        guard let board, let window = board.window else { return }
        // Main rather than key: a popover on the Board (the Capacity gauge's) takes key.
        if NSApp.isActive, window.isVisible, window.isMainWindow, window.attachedSheet == nil {
            board.closeAndHandBack()
        } else {
            showBoard()
        }
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
