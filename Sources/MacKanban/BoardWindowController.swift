import AppKit
import KanbanCore

/// The Board window: a toolbar with New Card above the three fixed Columns.
@MainActor
final class BoardWindowController: NSWindowController, NSToolbarDelegate {
    private let boardView: BoardViewController
    private let gauge = CapacityGauge()

    init(board: Board) {
        boardView = BoardViewController(board: board)
        let gauge = gauge
        boardView.onCapacityChange = { gauge.show($0) }
        let window = NSWindow(contentViewController: boardView)
        window.title = "MacKanban"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 900, height: 600))
        window.minSize = NSSize(width: 600, height: 360)
        window.isReleasedWhenClosed = false
        super.init(window: window)

        let toolbar = NSToolbar(identifier: "Board")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        // After the toolbar: adding it later would grow the restored frame on every launch.
        window.setFrameAutosaveName("Board")
        if !window.setFrameUsingName("Board") { window.center() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func reload() {
        boardView.reload()
    }

    @objc func newCard(_ sender: Any?) {
        boardView.newCard()
    }

    // MARK: NSToolbarDelegate

    private static let newCardItem = NSToolbarItem.Identifier("newCard")
    private static let capacityItem = NSToolbarItem.Identifier("capacity")

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, Self.capacityItem, Self.newCardItem]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        if identifier == Self.capacityItem {
            let item = NSToolbarItem(itemIdentifier: identifier)
            item.label = "Capacity"
            item.view = gauge
            return item
        }
        guard identifier == Self.newCardItem else { return nil }
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = "New Card"
        item.toolTip = "New Card (⌘N)"
        item.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "New Card")
        item.isBordered = true
        item.target = self
        item.action = #selector(newCard(_:))
        return item
    }
}
