import AppKit
import KanbanCore

/// The Archive window (⌘⇧A): archived Done Cards and Discarded Cards, the most
/// recently ended first, read-only. A double-click or Return opens a Card.
@MainActor
final class ArchiveWindowController: NSWindowController {
    private let archive: ArchiveViewController

    init(board: Board) {
        archive = ArchiveViewController(board: board)
        let window = NSWindow(contentViewController: archive)
        window.title = "Archive"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 640, height: 420))
        window.minSize = NSSize(width: 420, height: 240)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.setFrameAutosaveName("Archive")
        if !window.setFrameUsingName("Archive") { window.center() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func showWindow(_ sender: Any?) {
        archive.reload()
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    /// After a change on the Board: a Discard shows up here straight away.
    func reload() {
        guard let window, window.isVisible || window.isMiniaturized else { return }
        archive.reload()
    }
}

@MainActor
private final class ArchiveViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let board: Board
    private var cards: [ArchivedCard] = []
    private let table = ArchiveTableView()
    private let emptyLabel = NSTextField(labelWithString: "Nothing in the Archive yet.")
    private var refreshTimer: Timer?

    private enum ColumnID {
        static let title = NSUserInterfaceItemIdentifier("title")
        static let outcome = NSUserInterfaceItemIdentifier("outcome")
        static let created = NSUserInterfaceItemIdentifier("created")
        static let ended = NSUserInterfaceItemIdentifier("ended")
    }

    init(board: Board) {
        self.board = board
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func loadView() {
        // The outcome sits next to its date (decided 2026-10-24), both from the Card's events.
        for (id, title, width) in [(ColumnID.title, "Card", 250.0), (ColumnID.created, "Created", 110),
                                   (ColumnID.outcome, "Done/Discarded", 110), (ColumnID.ended, "Date", 110)] {
            let column = NSTableColumn(identifier: id)
            column.title = title
            column.width = width
            column.minWidth = 60
            table.addTableColumn(column)
        }
        table.usesAlternatingRowBackgroundColors = true
        table.style = .inset
        table.allowsMultipleSelection = false
        table.dataSource = self
        table.delegate = self
        table.target = self
        table.doubleAction = #selector(openClicked(_:))
        table.onReturn = { [weak self] in self?.openSelected() }

        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true

        // Over the scroll view, not inside it: a scroll view lays out its own subviews.
        let container = NSView()
        emptyLabel.textColor = .secondaryLabelColor
        for subview in [scroll, emptyLabel] as [NSView] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: container.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        view = container
    }

    // Done Cards reach the Archive as time passes, not only after a change.
    override func viewWillAppear() {
        super.viewWillAppear()
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshForAge() }
        }
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// Skipped while hidden (it reloads when shown) and while a Card is open.
    private func refreshForAge() {
        guard let window = view.window, window.isVisible, window.attachedSheet == nil else { return }
        reload()
    }

    /// Keeps the selected Card selected: new entries arrive at the top.
    func reload() {
        let selected = table.selectedRow >= 0 ? cards[table.selectedRow].id : nil
        do {
            cards = try board.archive()
        } catch {
            cards = []
            // One alert at a time: every Board change reloads this window.
            if let window = view.window, window.isVisible, window.attachedSheet == nil {
                NSAlert(error: error).beginSheetModal(for: window)
            }
        }
        table.reloadData()
        if let selected, let row = cards.firstIndex(where: { $0.id == selected }) {
            table.selectRowIndexes([row], byExtendingSelection: false)
        } else {
            table.deselectAll(nil)
        }
        emptyLabel.isHidden = !cards.isEmpty
    }

    // MARK: Table

    func numberOfRows(in tableView: NSTableView) -> Int {
        cards.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let id = tableColumn?.identifier else { return nil }
        let archived = cards[row]
        let text = switch id {
        case ColumnID.title: archived.card.title
        case ColumnID.outcome: archived.outcome == .done ? "Done" : "Discarded"
        case ColumnID.created: archived.created.formatted(date: .abbreviated, time: .omitted)
        default: archived.ended.formatted(date: .abbreviated, time: .omitted)
        }
        let cell = tableView.makeView(withIdentifier: id, owner: self) as? NSTextField ?? {
            let field = NSTextField(labelWithString: "")
            field.identifier = id
            field.lineBreakMode = .byTruncatingTail
            return field
        }()
        cell.stringValue = text
        cell.textColor = id == ColumnID.title ? .labelColor : .secondaryLabelColor
        if id == ColumnID.created || id == ColumnID.ended {
            cell.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }
        return cell
    }

    @objc private func openClicked(_ sender: Any?) {
        guard table.clickedRow >= 0 else { return }
        open(cards[table.clickedRow])
    }

    private func openSelected() {
        guard table.selectedRow >= 0 else { return }
        open(cards[table.selectedRow])
    }

    private func open(_ archived: ArchivedCard) {
        guard presentedViewControllers?.isEmpty ?? true else { return }
        presentAsSheet(CardSheetViewController(mode: archived.outcome == .done ? .readOnly(archived.card) : .discarded(archived.card)))
    }
}

/// Return opens the selected Card, as on the Board.
private final class ArchiveTableView: NSTableView {
    var onReturn: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76 {  // Return, Enter
            onReturn?()
        } else {
            super.keyDown(with: event)
        }
    }
}
