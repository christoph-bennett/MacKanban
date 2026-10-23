import AppKit
import KanbanCore

/// The three Columns side by side, each listing its Cards. A clicked Card is
/// selected; ⌘→ and ⌘← (the Card menu) or dragging move it between Columns.
@MainActor
final class BoardViewController: NSViewController, NSMenuItemValidation {
    private let board: Board
    private let columnViews = Column.allCases.map { ColumnView(column: $0) }
    private var selectedCard: UUID?

    init(board: Board) {
        self.board = board
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func loadView() {
        let columns = BoardView(views: columnViews)
        columns.orientation = .horizontal
        columns.distribution = .fillEqually
        columns.alignment = .top
        columns.spacing = 12
        columns.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        for view in columnViews {
            view.heightAnchor.constraint(equalTo: columns.heightAnchor, constant: -32).isActive = true
            view.onSelect = { [weak self] card in self?.select(card) }
            view.onDrop = { [weak self] card, column in self?.move(card, to: column) }
        }
        view = columns
        reload()
    }

    func reload() {
        do {
            let columns = try board.columns()
            for view in columnViews {
                view.show(columns[view.column] ?? [], selected: selectedCard)
            }
            let wip = WIPStatus(count: columns[.doing]?.count ?? 0, limit: board.wipLimit)
            columnViews.first { $0.column == .doing }?.showCount("\(wip.count) / \(wip.limit)", isWarning: wip.isOverLimit)
        } catch {
            show(error)
        }
    }

    func newCard() {
        guard presentedViewControllers?.isEmpty ?? true else { return }  // the sheet is already open
        let sheet = NewCardViewController()
        sheet.onCreate = { [weak self, weak sheet] title, notes in
            guard let self, let sheet else { return }
            do {
                try board.createCard(title: title, notes: notes)
                reload()
                dismiss(sheet)
            } catch {
                presentError(error)
            }
        }
        presentAsSheet(sheet)
    }

    /// Only redraws the selection: rebuilding the Card views would replace the
    /// one being clicked, and a drag starting from it would have no window.
    private func select(_ card: UUID) {
        selectedCard = card
        view.window?.makeFirstResponder(view)  // so the Card menu's shortcuts reach this controller
        for view in columnViews { view.select(card) }
    }

    private func move(_ card: UUID, to column: Column) {
        do {
            try board.move(card, to: column)
            selectedCard = card
            reload()
        } catch {
            show(error)
        }
    }

    /// The Column the selected Card is in, if a Card is selected.
    private var selectedColumn: Column? {
        columnViews.first { $0.contains(selectedCard) }?.column
    }

    @objc func moveToNextColumn(_ sender: Any?) {
        step(by: 1)
    }

    @objc func moveToPreviousColumn(_ sender: Any?) {
        step(by: -1)
    }

    /// Moves the selected Card one Column right or left. Off the Board's edge
    /// there's nothing to explain, so it only beeps; the Board explains the rest.
    private func step(by offset: Int) {
        guard let selectedCard, let target = column(by: offset) else { return NSSound.beep() }
        move(selectedCard, to: target)
    }

    /// The Column `offset` steps from the selected Card's, if the Board has one there.
    private func column(by offset: Int) -> Column? {
        guard let column = selectedColumn, let index = Column.allCases.firstIndex(of: column),
              Column.allCases.indices.contains(index + offset)
        else { return nil }
        return Column.allCases[index + offset]
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(moveToNextColumn(_:)): column(by: 1) != nil
        case #selector(moveToPreviousColumn(_:)): column(by: -1) != nil
        default: true
        }
    }

    /// A refused move or a store error, as a sheet on the Board window.
    private func show(_ error: Error) {
        if let window = view.window {
            NSAlert(error: error).beginSheetModal(for: window)
        } else {
            presentError(error)
        }
    }
}

/// The Board's content view. It takes first responder when a Card is clicked,
/// which puts the view controller in the responder chain for the Card menu.
private final class BoardView: NSStackView {
    override var acceptsFirstResponder: Bool { true }
}

private extension NSPasteboard.PasteboardType {
    /// A dragged Card: its ID as a string. Only meaningful inside MacKanban.
    static let card = NSPasteboard.PasteboardType("com.onethingwell.mackanban.card")
}

/// One Column: its title above its Cards, which scroll when they don't fit.
@MainActor
private final class ColumnView: NSView {
    let column: Column
    var onSelect: ((UUID) -> Void)?
    var onDrop: ((_ card: UUID, _ column: Column) -> Void)?
    private let cards = NSStackView()
    private let count = NSTextField(labelWithString: "")
    private var cardIDs: [UUID] { cards.arrangedSubviews.compactMap { ($0 as? CardView)?.card.id } }
    private var isDropTarget = false {
        didSet { needsDisplay = true }
    }

    init(column: Column) {
        self.column = column
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 10
        setAccessibilityLabel(column.title)
        registerForDraggedTypes([.card])

        let title = NSTextField(labelWithString: column.title)
        title.font = .preferredFont(forTextStyle: .headline)
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)
        count.font = .monospacedDigitSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .headline).pointSize, weight: .regular)
        count.translatesAutoresizingMaskIntoConstraints = false
        addSubview(count)

        cards.orientation = .vertical
        cards.alignment = .leading
        cards.spacing = 8
        cards.edgeInsets = NSEdgeInsets(top: 0, left: 12, bottom: 12, right: 12)
        cards.translatesAutoresizingMaskIntoConstraints = false
        let document = FlippedView()
        document.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(cards)

        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.documentView = document
        scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            title.trailingAnchor.constraint(lessThanOrEqualTo: count.leadingAnchor, constant: -8),
            count.firstBaselineAnchor.constraint(equalTo: title.firstBaselineAnchor),
            count.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            scroll.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            document.topAnchor.constraint(equalTo: scroll.contentView.topAnchor),
            document.leadingAnchor.constraint(equalTo: scroll.contentView.leadingAnchor),
            document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
            cards.topAnchor.constraint(equalTo: document.topAnchor),
            cards.leadingAnchor.constraint(equalTo: document.leadingAnchor),
            cards.trailingAnchor.constraint(equalTo: document.trailingAnchor),
            cards.bottomAnchor.constraint(equalTo: document.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func show(_ cards: [Card], selected: UUID?) {
        for view in self.cards.arrangedSubviews { view.removeFromSuperview() }
        for card in cards {
            let view = CardView(card: card, isSelected: card.id == selected)
            view.onSelect = { [weak self] in self?.onSelect?(card.id) }
            self.cards.addArrangedSubview(view)
            view.widthAnchor.constraint(equalTo: self.cards.widthAnchor, constant: -24).isActive = true
        }
    }

    /// Text on the right of the Column's title, e.g. Doing's "2 / 3".
    func showCount(_ text: String, isWarning: Bool) {
        count.stringValue = text
        count.textColor = isWarning ? .systemRed : .secondaryLabelColor
        count.setAccessibilityLabel(isWarning ? "\(text), over the WIP Limit" : text)
    }

    func contains(_ card: UUID?) -> Bool {
        card.map(cardIDs.contains) ?? false
    }

    func select(_ card: UUID) {
        for case let view as CardView in cards.arrangedSubviews {
            view.isSelected = view.card.id == card
        }
    }

    // MARK: Dropping a Card

    /// Not for a Card that's already here: dropping it back is a cancelled drag.
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let card = Self.card(in: sender), !contains(card) else { return [] }
        isDropTarget = true
        return .move
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDropTarget = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isDropTarget = false
        guard let card = Self.card(in: sender), !contains(card) else { return false }
        // The Board decides whether the move is allowed and explains when it isn't.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            onDrop?(card, column)
        }
        return true
    }

    private static func card(in info: NSDraggingInfo) -> UUID? {
        info.draggingPasteboard.string(forType: .card).flatMap(UUID.init)
    }

    // A layer colour doesn't follow appearance changes on its own.
    override func updateLayer() {
        layer?.backgroundColor = (isDropTarget ? NSColor.controlAccentColor.withAlphaComponent(0.15)
            : NSColor.quaternaryLabelColor.withAlphaComponent(0.08)).cgColor
    }

    override var wantsUpdateLayer: Bool { true }
}

/// A Card on the Board: its title, and the start of its notes. Click to select
/// it, drag it to another Column to move it.
@MainActor
private final class CardView: NSView, NSDraggingSource {
    var onSelect: (() -> Void)?
    let card: Card
    var isSelected: Bool {
        didSet {
            needsDisplay = true
            setAccessibilitySelected(isSelected)
        }
    }

    init(card: Card, isSelected: Bool) {
        self.card = card
        self.isSelected = isSelected
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 8
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel(card.title)
        setAccessibilitySelected(isSelected)

        let title = NSTextField(wrappingLabelWithString: card.title)
        title.font = .preferredFont(forTextStyle: .body)
        title.isSelectable = false
        let stack = NSStackView(views: [title])
        if !card.notes.isEmpty {
            let notes = NSTextField(wrappingLabelWithString: card.notes)
            notes.font = .preferredFont(forTextStyle: .callout)
            notes.textColor = .secondaryLabelColor
            notes.isSelectable = false
            notes.maximumNumberOfLines = 3
            notes.lineBreakMode = .byTruncatingTail
            stack.addArrangedSubview(notes)
        }
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        for label in stack.arrangedSubviews {
            label.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -20).isActive = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// The whole Card is one target: clicks and drags on its labels select or
    /// drag the Card, and the labels show no text cursor.
    override func hitTest(_ point: NSPoint) -> NSView? {
        frame.contains(point) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        onSelect?()
    }

    override func mouseDragged(with event: NSEvent) {
        let item = NSPasteboardItem()
        item.setString(card.id.uuidString, forType: .card)
        let dragged = NSDraggingItem(pasteboardWriter: item)
        dragged.setDraggingFrame(bounds, contents: snapshot())
        beginDraggingSession(with: [dragged], event: event, source: self)
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        context == .withinApplication ? .move : []
    }

    private func snapshot() -> NSImage {
        let image = NSImage(size: bounds.size)
        if let bitmap = bitmapImageRepForCachingDisplay(in: bounds) {
            cacheDisplay(in: bounds, to: bitmap)
            image.addRepresentation(bitmap)
        }
        return image
    }

    override func updateLayer() {
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.borderColor = (isSelected ? NSColor.controlAccentColor : NSColor.separatorColor).cgColor
        layer?.borderWidth = isSelected ? 2 : 1
    }

    override var wantsUpdateLayer: Bool { true }
}

/// Lays the Cards out from the top of the scroll view, not the bottom.
private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
