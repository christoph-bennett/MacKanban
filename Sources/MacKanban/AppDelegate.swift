import AppKit
import KanbanCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var board: BoardWindowController?
    private var terminationSignal: DispatchSourceSignal?

    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            board = BoardWindowController(board: try Board(storeURL: Self.storeURL))
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

    /// `~/Library/Application Support/MacKanban/Board.sqlite` (ADR 0002).
    private static var storeURL: URL {
        URL.applicationSupportDirectory.appending(components: "MacKanban", "Board.sqlite")
    }

    @objc func newCard() {
        showBoard()
        board?.newCard(nil)
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
