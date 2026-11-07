import AppKit
import KanbanCore

/// The Archive window (⌘⇧A): a Done section, then a Discarded section, each the
/// most recently ended first, read-only (spec 0003). A double-click or Return opens
/// a Card; Esc closes the window.
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
    /// The Archive's two sections, in the order shown (spec 0003).
    private enum Section: CaseIterable {
        case done, discarded

        var title: String {
            switch self {
            case .done: "Done"
            case .discarded: "Discarded"
            }
        }
    }

    /// What the table shows: each non-empty section's heading, then its Cards.
    private enum Row {
        case heading(Section)
        case card(ArchivedCard, Section)

        var card: ArchivedCard? {
            if case let .card(card, _) = self { card } else { nil }
        }
    }

    private var rows: [Row] = []
    private let table = ArchiveTableView()
    private let emptyLabel = NSTextField(labelWithString: "Nothing in the Archive yet.")
    private var refreshTimer: Timer?

    /// The cell of a section heading, which spans the row rather than a column.
    private static let headingCellID = NSUserInterfaceItemIdentifier("heading")

    private enum ColumnID {
        static let title = NSUserInterfaceItemIdentifier("title")
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
        // No Outcome column: the section says it (spec 0003). Ended is when the Card
        // was finished or Discarded, as its section heading says.
        for (id, title, width) in [(ColumnID.title, "Card", 240.0), (ColumnID.created, "Created", 110),
                                   (ColumnID.ended, "Ended", 150)] {
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

    /// Keeps the selected Card selected: new entries arrive at the top of their section.
    func reload() {
        let selected = selectedCard?.id
        do {
            let archive = try board.archive()
            rows = Section.allCases.flatMap { section -> [Row] in
                let cards = section == .done ? archive.done : archive.discarded
                guard !cards.isEmpty else { return [] }  // an empty section isn't shown
                return [.heading(section)] + cards.map { .card($0, section) }
            }
        } catch {
            rows = []
            // One alert at a time: every Board change reloads this window.
            if let window = view.window, window.isVisible, window.attachedSheet == nil {
                NSAlert(error: error).beginSheetModal(for: window)
            }
        }
        table.reloadData()
        if let selected, let row = rows.firstIndex(where: { $0.card?.id == selected }) {
            table.selectRowIndexes([row], byExtendingSelection: false)
        } else {
            table.deselectAll(nil)
        }
        emptyLabel.isHidden = !rows.isEmpty
    }

    private var selectedCard: ArchivedCard? {
        rows.indices.contains(table.selectedRow) ? rows[table.selectedRow].card : nil
    }

    // MARK: Table

    func numberOfRows(in tableView: NSTableView) -> Int {
        rows.count
    }

    /// Section headings span the row and can't be selected; the arrow keys pass over them.
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        rows[row].card == nil
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        rows[row].card != nil
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let archived = rows[row].card else {
            guard case let .heading(section) = rows[row] else { return nil }
            let cell = tableView.makeView(withIdentifier: Self.headingCellID, owner: self) as? NSTableCellView ?? Self.cell(Self.headingCellID)
            cell.textField?.stringValue = section.title
            cell.textField?.font = .boldSystemFont(ofSize: NSFont.systemFontSize)
            cell.textField?.textColor = .secondaryLabelColor
            cell.textField?.setAccessibilityRoleDescription("section heading")  // VoiceOver: "Done, section heading"
            return cell
        }
        guard let id = tableColumn?.identifier else { return nil }
        let text = switch id {
        case ColumnID.title: archived.card.title
        case ColumnID.created: archived.created.formatted(date: .abbreviated, time: .omitted)
        default: archived.ended.formatted(date: .abbreviated, time: .shortened)  // when it was finished or Discarded
        }
        let cell = tableView.makeView(withIdentifier: id, owner: self) as? NSTableCellView ?? Self.cell(id)
        guard let field = cell.textField else { return cell }
        field.stringValue = text
        field.textColor = id == ColumnID.title ? .labelColor : .secondaryLabelColor
        if id == ColumnID.created || id == ColumnID.ended {
            field.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        }
        return cell
    }

    /// A cell view with its text field centred in the row, as AppKit's own cells
    /// are; a bare text field draws its text at the top of the row.
    private static func cell(_ id: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = id
        let field = NSTextField(labelWithString: "")
        field.lineBreakMode = .byTruncatingTail
        field.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(field)
        cell.textField = field  // also gives it the selected row's text colours
        NSLayoutConstraint.activate([
            field.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
            field.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
            field.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        return cell
    }

    /// Esc closes the Archive (an open Card's sheet gets Esc first and closes itself).
    override func cancelOperation(_ sender: Any?) {
        view.window?.performClose(sender)
    }

    @objc private func openClicked(_ sender: Any?) {
        guard rows.indices.contains(table.clickedRow) else { return }
        open(rows[table.clickedRow])
    }

    private func openSelected() {
        guard rows.indices.contains(table.selectedRow) else { return }
        open(rows[table.selectedRow])
    }

    /// Read-only: "Done Card" or "Discarded Card", by the section it's in.
    private func open(_ row: Row) {
        guard case let .card(archived, section) = row, presentedViewControllers?.isEmpty ?? true else { return }
        presentAsSheet(CardSheetViewController(mode: section == .done ? .readOnly(archived.card) : .discarded(archived.card)))
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
