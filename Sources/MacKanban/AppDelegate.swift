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
        let isRealStore = Self.storeOverride == nil
        let defaults = Self.defaults
        do {
            let model = try Board(storeURL: Self.storeURL, wipLimit: defaults.integer(forKey: SettingsWindowController.wipLimitKey),
                                  archiveDelay: defaults.integer(forKey: SettingsWindowController.archiveDelayKey))
            let board = BoardWindowController(board: model)
            let settings = SettingsWindowController(board: model, defaults: defaults, offersLaunchAtLogin: isRealStore,
                                                     registersHotkey: isRealStore)
            settings.onBoardSettingChange = { [weak board] in board?.reload() }  // its state change reloads the Archive too
            board.showsAges = defaults.bool(forKey: SettingsWindowController.showsAgesKey)
            settings.onShowsAgesChange = { [weak board] in board?.showsAges = $0 }
            settings.onShowsInDockChange = { Self.switchDock(to: $0) }
            let statusItem = StatusItemController(board: model)
            statusItem.onNewCard = { [weak self] in self?.newCard() }
            statusItem.onOpenBoard = { [weak self] in self?.showBoard() }
            statusItem.onOpenArchive = { [weak self] in self?.showArchive() }
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
            archive.onRestore = { [weak board] in board?.reload() }  // the restored Card shows on the Board
            board.onStateChange = { [weak statusItem, weak archive] in
                statusItem?.show($0)
                archive?.reload()
            }
            self.archive = archive
            self.board = board
            self.settings = settings
            self.statusItem = statusItem
        } catch {
            NSApp.activateAsAsked()  // also when opened at login, with another app in use
            let alert = NSAlert(error: error)
            alert.messageText = "MacKanban can't open its Board."
            alert.informativeText = "\(error.localizedDescription)\n\nThe store is \(Self.storeURL.path)."
            alert.runModal()
            NSApp.terminate(nil)
            return
        }
        NSApp.mainMenu = MainMenu.make(appDelegate: self)
        // A sample store's MacKanban leaves the hotkeys to the real one.
        if isRealStore {
            Hotkey.all.forEach { $0.checkAvailableBeforeRegistering() }
            KeyboardShortcuts.onKeyDown(for: .showBoard) { [weak self] in self?.toggleBoard() }
            KeyboardShortcuts.onKeyDown(for: .newCard) { [weak self] in self?.newCardFromHotkey() }
        }
        quitNormallyOnTerminationSignal()
        showBoard()  // activates MacKanban too
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

    /// The settings: the real ones, or a sample store's own, so trying things on a
    /// sample Board can't change the real WIP Limit, Archive Delay or Dock icon.
    private static let defaults: UserDefaults = {
        let defaults = storeOverride == nil ? UserDefaults.standard : UserDefaults(suiteName: "com.onethingwell.mackanban.sample")!
        defaults.register(defaults: [SettingsWindowController.wipLimitKey: Board.defaultWIPLimit,
                                     SettingsWindowController.archiveDelayKey: Board.defaultArchiveDelay,
                                     SettingsWindowController.showsAgesKey: true,
                                     SettingsWindowController.showsInDockKey: true])
        return defaults
    }()

    /// With the Dock icon (and the app switcher and menu bar that come with it), or
    /// without, from the menu bar extra and the hotkeys only (spec 0004). At launch
    /// from the stored setting, before any window shows.
    static func applyDockSetting(_ showsInDock: Bool? = nil) {
        let showsInDock = showsInDock ?? defaults.bool(forKey: SettingsWindowController.showsInDockKey)
        NSApp.setActivationPolicy(showsInDock ? .regular : .accessory)
    }

    /// From Settings. Switching off deactivates MacKanban, twice in a row, and
    /// reactivating brought only the key window back, so the Board fell behind the
    /// app below it. Once that has settled, every window goes back in front in the
    /// order it had (spec 0004, story 20).
    /// Switching again before the last restore has run keeps that restore and its
    /// window order: a second snapshot would see the windows already pushed back.
    private static func switchDock(to showsInDock: Bool) {
        let restore = WindowOrderRestore.pending ?? WindowOrderRestore(NSApp.orderedWindows.filter(\.isVisible))
        applyDockSetting(showsInDock)
        restore.schedule()
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
    /// Dock, menus), so it insists on activating.
    @objc func showBoard() {
        guard let board else { return }  // the store didn't open and MacKanban is quitting
        board.showWindow(nil)
        board.window?.makeKeyAndOrderFront(nil)
        NSApp.activateAsAsked()
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

    /// The New Card hotkey (MVP ticket 17): the Board to the front with the New Card
    /// sheet on it, as ⌘N opens it. A sheet already on the Board stays and nothing
    /// new opens. Called from another app, closing the sheet closes the Board as Esc
    /// does and hands back to that app; called with MacKanban in front, the Board stays.
    func newCardFromHotkey() {
        guard let board else { return }
        let cameFromAnotherApp = !NSApp.isActive
        showBoard()
        board.newCard(handingBackOnClose: cameFromAnotherApp)
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

/// Puts MacKanban's windows back in front, in the order they had, after a Dock
/// switch. macOS deactivates MacKanban once on the switch and again about 50 ms
/// later (seen 2026-11-07), so restoring right after the first was undone by the
/// second: each deactivation within the first second postpones the restore by
/// 0.2 s, and it runs once, when that has settled.
@MainActor
private final class WindowOrderRestore {
    /// The restore not yet run, if any.
    static private(set) var pending: WindowOrderRestore?

    private let windows: [NSWindow]
    private var observer: NSObjectProtocol?
    private var work: DispatchWorkItem?
    private var cutOff: DispatchWorkItem?
    private static let quietTime: TimeInterval = 0.2

    init(_ windows: [NSWindow]) {
        self.windows = windows
    }

    func schedule() {
        Self.pending = self
        if observer == nil {
            observer = NotificationCenter.default.addObserver(forName: NSApplication.didResignActiveNotification,
                                                              object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.postpone() }
            }
        }
        postpone()
        // Deactivations more than a second after the last switch aren't its.
        cutOff?.cancel()
        let stop = DispatchWorkItem { [self] in stopObserving() }
        cutOff = stop
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: stop)
    }

    private func postpone() {
        work?.cancel()
        let next = DispatchWorkItem { [self] in run() }
        work = next
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.quietTime, execute: next)
    }

    /// Windows closed in the meantime stay closed.
    private func run() {
        if Self.pending === self { Self.pending = nil }
        stopObserving()  // a deactivation after this is the user's, not the switch's
        let open = windows.filter(\.isVisible)
        NSApp.activateAsAsked()
        for window in open.reversed() { window.orderFront(nil) }
        open.first?.makeKey()
    }

    private func stopObserving() {
        cutOff?.cancel()
        if let observer { NotificationCenter.default.removeObserver(observer) }
        observer = nil
    }
}
