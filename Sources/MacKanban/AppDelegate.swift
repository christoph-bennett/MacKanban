import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let board = BoardWindowController()
    private var terminationSignal: DispatchSourceSignal?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = MainMenu.make(openBoardTarget: self)
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

    @objc func showBoard() {
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
