import AppKit
import KanbanCore

/// The Archive window (⌘⇧A): a Done section, then a Discarded section, each the
/// most recently ended first, read-only (spec 0003). A double-click or Return opens
/// a Card; Esc closes the window.
@MainActor
final class ArchiveWindowController: NSWindowController, NSWindowDelegate {
    private let archive: ArchiveViewController

    init(board: Board) {
        archive = ArchiveViewController(board: board)
        let window = NSWindow(contentViewController: archive)
        window.title = "Archive"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 780, height: 420))
        window.minSize = NSSize(width: 600, height: 240)  // room for the fixed columns and some of the title
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
        window.setFrameAutosaveName("Archive")
        if !window.setFrameUsingName("Archive") { window.center() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func showWindow(_ sender: Any?) {
        archive.reload()
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activateAsAsked()  // also from the menu bar extra
    }

    /// After a Restore here, or undoing one: the Board shows the Card (spec 0005).
    var onRestore: (() -> Void)? {
        get { archive.onRestore }
        set { archive.onRestore = newValue }
    }

    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? { BoardUndo.manager }

    /// A Restore that needs a Triage first: the Board does it (restore ticket 02).
    var onNeedsTriage: ((Card) -> Void)? {
        get { archive.onNeedsTriage }
        set { archive.onNeedsTriage = newValue }
    }

    /// After a change on the Board: a Discard shows up here straight away.
    func reload() {
        guard let window, window.isVisible || window.isMiniaturized else { return }
        archive.reload()
    }
}

@MainActor
private final class ArchiveViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSMenuDelegate {
    private let board: Board
    var onRestore: (() -> Void)?
    var onNeedsTriage: ((Card) -> Void)?
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
    /// When the Archive shown was read, on the Board's clock: the Counts bars measure from it.
    private var asOf = Date()
    private let table = ArchiveTableView()
    private let emptyLabel = NSTextField(labelWithString: "Nothing in the Archive yet.")
    private var refreshTimer: Timer?

    /// The cell of a section heading, which spans the row rather than a column.
    private static let headingCellID = NSUserInterfaceItemIdentifier("heading")

    private enum ColumnID {
        static let title = NSUserInterfaceItemIdentifier("title")
        static let created = NSUserInterfaceItemIdentifier("created")
        static let ended = NSUserInterfaceItemIdentifier("ended")
        static let counts = NSUserInterfaceItemIdentifier("counts")
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
        // Counts: how much longer an archived Done Card props up Capacity (spec 0003).
        for (id, title, width) in [(ColumnID.title, "Card", 200.0), (ColumnID.created, "Created", 110),
                                   (ColumnID.ended, "Ended", 160), (ColumnID.counts, "Counts", 140)] {
            let column = NSTableColumn(identifier: id)
            if id == ColumnID.counts {
                column.headerCell = InfoHeaderCell(title: title)
                column.headerToolTip = InfoHeaderCell.countsExplanation  // over the whole header, ⓘ included
            } else {
                column.title = title
            }
            column.width = width
            column.minWidth = id == ColumnID.counts ? 140 : 60  // the bar and "until Nov 10" stay whole
            column.resizingMask = id == ColumnID.title ? .autoresizingMask : .userResizingMask
            table.addTableColumn(column)
        }
        // A narrower window (its size is remembered) takes the room from the Card's title.
        table.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        table.usesAlternatingRowBackgroundColors = true
        table.style = .inset
        // VoiceOver can read the ⓘ; the header keeps the size AppKit gave it for this style.
        table.headerView = CountsHeaderView(frame: table.headerView?.frame ?? .zero, countsColumn: ColumnID.counts)
        table.allowsMultipleSelection = false
        table.dataSource = self
        table.delegate = self
        table.target = self
        table.doubleAction = #selector(openClicked(_:))
        table.onReturn = { [weak self] in self?.openSelected() }
        let menu = NSMenu()
        menu.delegate = self  // built for the clicked row: Restore on Discarded Cards only
        table.menu = menu

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
            asOf = archive.asOf
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
        // A Done Card past its 14 days no longer props up Capacity: its whole row fades.
        let expired = archived.countsUntil != nil && !archived.isCounting
        if id == ColumnID.counts {
            let cell = tableView.makeView(withIdentifier: id, owner: self) as? CountsCellView ?? CountsCellView(identifier: id)
            cell.show(archived, asOf: asOf)
            return cell
        }
        let text = switch id {
        case ColumnID.title: archived.card.title
        case ColumnID.created: archived.created.formatted(date: .abbreviated, time: .omitted)
        default: archived.ended.formatted(date: .abbreviated, time: .shortened)  // when it was finished or Discarded
        }
        let cell = tableView.makeView(withIdentifier: id, owner: self) as? NSTableCellView ?? Self.cell(id)
        guard let field = cell.textField else { return cell }
        field.stringValue = text
        field.textColor = switch (id == ColumnID.title, expired) {
        case (true, false): .labelColor
        case (true, true), (false, false): .secondaryLabelColor
        case (false, true): .tertiaryLabelColor
        }
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

    // MARK: Restore (spec 0005)

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        guard rows.indices.contains(table.clickedRow), case let .card(archived, .discarded) = rows[table.clickedRow],
              !archived.card.isSample else { return }
        let item = NSMenuItem(title: "Restore", action: #selector(restoreClicked(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = archived.card
        menu.addItem(item)
    }

    @objc private func restoreClicked(_ sender: NSMenuItem) {
        guard let card = sender.representedObject as? Card else { return }
        restore(card)
    }

    /// Back to Backlog if there's room for its whole cost; otherwise a sheet says why.
    private func restore(_ card: Card) {
        guard let window = view.window, window.attachedSheet == nil else { return NSSound.beep() }
        do {
            let gate = try board.restoreGate(card.id)
            switch gate.outcome {
            case .open:
                try restoreUndoably(card)
            case let .blocked(cardsToFree):
                RestoreRefusal.alert(card, gate: gate, cardsToFree: cardsToFree).beginSheetModal(for: window)
            case .triage:
                onNeedsTriage?(card)  // the Board comes forward with the Triage, then restores
            }
        } catch {
            NSAlert(error: error).beginSheetModal(for: window)
        }
    }

    /// Restores and registers the undo in the Board's shared history; undo and redo update the Board,
    /// which reloads this window too. A redo goes through the gate again, like a click.
    private func restoreUndoably(_ card: Card) throws {
        let change = try board.restore(card.id)
        onRestore?()
        guard let undoManager = view.window?.undoManager else { return }
        undoManager.registerUndo(withTarget: self) { controller in
            do {
                try controller.board.revert(change)
            } catch {
                return controller.showError(error)
            }
            controller.onRestore?()
            controller.view.window?.undoManager?.registerUndo(withTarget: controller) { controller in
                controller.restore(card)
            }
            controller.view.window?.undoManager?.setActionName("Restore")
        }
        undoManager.setActionName("Restore")
    }

    private func showError(_ error: Error) {
        guard let window = view.window, window.attachedSheet == nil else { return NSSound.beep() }
        NSAlert(error: error).beginSheetModal(for: window)
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
        let mode: CardSheetViewController.Mode = section == .done
            ? .done(archived.card, on: archived.ended, archived: true)
            : .discarded(archived.card, on: archived.ended)
        presentAsSheet(CardSheetViewController(mode: mode))
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

/// The Counts cell of an archived Done Card (spec 0003): a bar that drains from
/// full on the day the Card was finished to empty 14 days later, and "until Nov 10";
/// "no longer" once that's past. Empty for a Discarded Card, which never counts.
private final class CountsCellView: NSTableCellView {
    private let bar = NSLevelIndicator()
    private let label = NSTextField(labelWithString: "")
    private static let window = Capacity.throughputWindow

    init(identifier: NSUserInterfaceItemIdentifier) {
        super.init(frame: .zero)
        self.identifier = identifier
        bar.levelIndicatorStyle = .continuousCapacity
        bar.minValue = 0
        bar.maxValue = Self.window
        bar.setAccessibilityElement(false)  // the label says it
        label.textColor = .secondaryLabelColor
        label.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        label.lineBreakMode = .byTruncatingTail
        textField = label  // the selected row's text colours
        let stack = NSStackView(views: [bar, label])
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: 36),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -2),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// The bar's hover text: how long the Card still counts, in plain words, to the
    /// hour, so two bars of different length never say the same (asked for 2026-11-07).
    static func timeLeft(_ left: TimeInterval) -> String {
        let hours = Int(left / 3_600)
        let (days, rest) = (hours / 24, hours % 24)
        func count(_ n: Int, _ unit: String) -> String { n == 1 ? "1 \(unit)" : "\(n) \(unit)s" }
        return switch (days, rest) {
        case (0, 0): "Counts for less than an hour more"
        case (0, _): "Counts for another \(count(rest, "hour"))"
        case (_, 0): "Counts for another \(count(days, "day"))"
        default: "Counts for another \(count(days, "day")) and \(count(rest, "hour"))"
        }
    }

    /// Whether it counts comes from the Board (Capacity's rule and clock); the bar
    /// only shows how much of the 14 days is left at `asOf`.
    func show(_ archived: ArchivedCard, asOf: Date) {
        guard let countsUntil = archived.countsUntil else {
            bar.isHidden = true
            label.stringValue = ""
            label.setAccessibilityLabel(nil)
            return
        }
        let date = countsUntil.formatted(.dateTime.month(.abbreviated).day())
        bar.isHidden = !archived.isCounting
        let left = min(max(countsUntil.timeIntervalSince(asOf), 0), Self.window)
        bar.doubleValue = left
        bar.toolTip = Self.timeLeft(left)  // the date stays beside it (asked for 2026-11-07)
        label.stringValue = archived.isCounting ? "until \(date)" : "no longer"
        label.textColor = archived.isCounting ? .secondaryLabelColor : .tertiaryLabelColor
        label.setAccessibilityLabel(archived.isCounting ? "Counts toward Throughput until \(date)" : "No longer counts toward Throughput")
    }
}

/// The Counts column's header: its title, then an ⓘ that explains the column in plain
/// words (asked for 2026-11-07, archive ticket 07). The ⓘ is part of the title, so the
/// header lays both out together. The column's header tooltip shows the explanation;
/// for VoiceOver, `CountsHeaderView` adds it as an element of its own.
private final class InfoHeaderCell: NSTableHeaderCell {
    /// The 14 days are Capacity's Throughput window, the same the bars drain over.
    static var countsExplanation: String {
        "Done or Archived Cards each give you room for one more Card, for \(Capacity.throughputWindowDays) days after they moved to Done. "
            + "The bar shows how much of that time is left. After that, the Card stays here but no longer gives you room."
    }

    /// The column's title is the cell's own text: setting `column.title` would drop the ⓘ.
    convenience init(title: String) {
        self.init(textCell: title)
        let font = font ?? .systemFont(ofSize: NSFont.smallSystemFontSize)
        let config = NSImage.SymbolConfiguration(pointSize: font.pointSize, weight: .regular)
            .applying(NSImage.SymbolConfiguration(paletteColors: [.secondaryLabelColor]))
        guard let icon = NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return }
        let attachment = NSTextAttachment()
        attachment.image = icon
        attachment.bounds = NSRect(x: 0, y: ((font.capHeight - icon.size.height) / 2).rounded(),
                                   width: icon.size.width, height: icon.size.height)
        // The thin space and the ⓘ take the title's font and paragraph, so the line stays as tall.
        let attributes = attributedStringValue.length > 0 ? attributedStringValue.attributes(at: 0, effectiveRange: nil) : [.font: font]
        let full = NSMutableAttributedString(attributedString: attributedStringValue)
        full.append(NSAttributedString(string: "\u{2009}", attributes: attributes))
        let iconRun = NSMutableAttributedString(attachment: attachment)
        iconRun.addAttributes(attributes, range: NSRange(location: 0, length: iconRun.length))
        full.append(iconRun)
        attributedStringValue = full
        setAccessibilityTitle(title)  // VoiceOver reads "Counts", not the attachment's placeholder
    }
}

/// The Archive's header, with one extra element for VoiceOver over the Counts header:
/// "About Counts", whose value is the explanation the ⓘ shows on hover. AppKit's own
/// header elements take no help text (tried, archive ticket 07).
private final class CountsHeaderView: NSTableHeaderView {
    private let countsColumn: NSUserInterfaceItemIdentifier
    private let info = NSAccessibilityElement()

    init(frame: NSRect, countsColumn: NSUserInterfaceItemIdentifier) {
        self.countsColumn = countsColumn
        super.init(frame: frame)
        info.setAccessibilityRole(.staticText)
        info.setAccessibilityLabel("About Counts")
        info.setAccessibilityValue(InfoHeaderCell.countsExplanation)
        info.setAccessibilityParent(self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func accessibilityChildren() -> [Any]? {
        guard let tableView, case let index = tableView.column(withIdentifier: countsColumn), index >= 0 else {
            return super.accessibilityChildren()
        }
        info.setAccessibilityFrameInParentSpace(headerRect(ofColumn: index))  // follows resizing and moving
        return (super.accessibilityChildren() ?? []) + [info]
    }
}

/// Why a free slot on the Board isn't enough for a Restore (spec 0005, story 18):
/// shown by the Archive, and by the Board when a Triage left no room.
@MainActor
enum RestoreRefusal {
    static func alert(_ card: Card, gate: RestoreGate, cardsToFree: Int) -> NSAlert {
        func count(_ n: Int) -> String { n == 1 ? "1 Card" : "\(n) Cards" }
        let age = switch AgeAmount(gate.age) {
        case .underAnHour: "less than an hour"
        case let .hours(n): n == 1 ? "1 hour" : "\(n) hours"
        case let .days(n): n == 1 ? "1 day" : "\(n) days"
        }
        let urgency = gate.urgency.formatted(.number.precision(.fractionLength(1)))
        let cost = gate.cost == 1 ? "It takes up the room of 1 Card."
            : "It's \(age) old, so it takes up the room of \(count(gate.cost)): 1 for the Card and \(urgency) for its age"
                + (abs(Double(gate.cost - 1) - gate.urgency) < 0.05 ? "." : ", counted in whole Cards as Capacity counts.")
        let room = gate.free > 0 ? "The Board has room for \(count(gate.free))." : "The Board has no room left."
        let alert = NSAlert()
        alert.messageText = "No room to restore “\(card.title)”"
        alert.informativeText = "\(cost) \(room) Finish or Discard \(count(cardsToFree)) first."
        return alert
    }
}
