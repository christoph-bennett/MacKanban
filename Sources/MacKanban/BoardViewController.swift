import AppKit
import KanbanCore

/// The three Columns side by side, each listing its Cards. A clicked Card is
/// selected; ⌘→ and ⌘← (the Card menu) or dragging move it between Columns.
/// Its pencil, a double-click or Return opens it; ⌘⌫ or its context menu Discards it.
@MainActor
final class BoardViewController: NSViewController, NSMenuItemValidation {
    private let board: Board
    private let columnViews = Column.allCases.map { ColumnView(column: $0) }
    private var selectedCard: UUID?
    private var refreshTimer: Timer?

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
            view.onOpen = { [weak self] card in self?.open(card) }
            view.onDiscard = { [weak self] card in self?.discard(card) }
        }
        view = columns
        reload()
        // Cards age while nothing happens; once a minute keeps tints and labels current.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshForAge() }
        }
    }

    /// Skipped while the window is hidden (it reloads when it appears), while a
    /// sheet is up (a store error would otherwise stack a new alert every minute),
    /// and while a mouse button is down (rebuilding the Cards mid-drag would remove
    /// the Card being dragged). The next tick catches up.
    private func refreshForAge() {
        guard let window = view.window, window.isVisible, window.attachedSheet == nil,
              NSEvent.pressedMouseButtons == 0
        else { return }
        reload()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
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
        presentCardSheet(.new) { [board] title, notes in try board.createCard(title: title, notes: notes) }
    }

    /// Opens the Card's sheet: editable in Backlog and Doing, read-only in Done.
    private func open(_ id: UUID) {
        guard let (card, column) = cardOnScreen(id) else { return }
        select(id)
        if column == .done {
            presentCardSheet(.readOnly(card))
        } else {
            presentCardSheet(.edit(card)) { [board] title, notes in try board.edit(id, title: title, notes: notes) }
        }
    }

    /// - Parameter save: what Save does; `nil` for the read-only sheet, which has none.
    private func presentCardSheet(_ mode: CardSheetViewController.Mode, save: ((String, String) throws -> Void)? = nil) {
        guard !isShowingSheet else { return }
        let sheet = CardSheetViewController(mode: mode)
        guard let save else { return presentAsSheet(sheet) }
        sheet.onSave = { [weak self, weak sheet] title, notes in
            guard let self, let sheet else { return }
            do {
                try save(title, notes)
                reload()
                dismiss(sheet)
            } catch {
                presentError(error)
            }
        }
        presentAsSheet(sheet)
    }

    private func discard(_ id: UUID) {
        do {
            try board.discard(id)
            if selectedCard == id { selectedCard = nil }
            reload()
        } catch {
            show(error)
        }
    }

    private func cardOnScreen(_ id: UUID) -> (Card, Column)? {
        for view in columnViews {
            if let card = view.card(id) { return (card, view.column) }
        }
        return nil
    }

    /// Return opens the selected Card.
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 76, let selectedCard {  // Return, Enter
            open(selectedCard)
        } else {
            super.keyDown(with: event)
        }
    }

    @objc func editCard(_ sender: Any?) {
        selectedCard.map(open)
    }

    @objc func discardCard(_ sender: Any?) {
        selectedCard.map(discard)
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

    private var isShowingSheet: Bool {
        !(presentedViewControllers?.isEmpty ?? true)
    }

    /// The Card menu acts on the selected Card, so it's off while a sheet is up:
    /// ⌘⌫ or ⌘→ typed in the edit sheet must not Discard or move the Card being edited.
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(editCard(_:)) {
            menuItem.title = selectedColumn == .done ? "Open Card…" : "Edit Card…"
        }
        if isShowingSheet,
           [#selector(moveToNextColumn(_:)), #selector(moveToPreviousColumn(_:)), #selector(editCard(_:)),
            #selector(discardCard(_:))].contains(menuItem.action) {
            return false
        }
        return switch menuItem.action {
        case #selector(moveToNextColumn(_:)): column(by: 1) != nil
        case #selector(moveToPreviousColumn(_:)): column(by: -1) != nil
        case #selector(editCard(_:)): selectedColumn != nil
        case #selector(discardCard(_:)): selectedColumn == .backlog || selectedColumn == .doing
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
    var onOpen: ((UUID) -> Void)?
    var onDiscard: ((UUID) -> Void)?
    private let cards = NSStackView()
    private let count = NSTextField(labelWithString: "")
    private var cardIDs: [UUID] { cards.arrangedSubviews.compactMap { ($0 as? CardView)?.card.id } }
    private var isDropTarget = false {
        didSet { needsDisplay = true }
    }
    /// Doing above its WIP Limit (after the limit was lowered): the whole Column turns red.
    private var isOverLimit = false {
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
            let view = CardView(card: card, in: column, isSelected: card.id == selected)
            view.onSelect = { [weak self] in self?.onSelect?(card.id) }
            view.onOpen = { [weak self] in self?.onOpen?(card.id) }
            view.onDiscard = { [weak self] in self?.onDiscard?(card.id) }
            self.cards.addArrangedSubview(view)
            view.widthAnchor.constraint(equalTo: self.cards.widthAnchor, constant: -24).isActive = true
        }
    }

    /// Text on the right of the Column's title, e.g. Doing's "2 / 3".
    func showCount(_ text: String, isWarning: Bool) {
        count.stringValue = text
        count.textColor = isWarning ? .systemRed : .secondaryLabelColor
        isOverLimit = isWarning
        count.setAccessibilityLabel(isWarning ? "\(text), over the WIP Limit" : text)
    }

    func contains(_ card: UUID?) -> Bool {
        card.map(cardIDs.contains) ?? false
    }

    func card(_ id: UUID) -> Card? {
        cards.arrangedSubviews.lazy.compactMap { ($0 as? CardView)?.card }.first { $0.id == id }
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
        let background: NSColor = if isDropTarget {
            .controlAccentColor.withAlphaComponent(0.15)
        } else if isOverLimit {
            .systemRed.withAlphaComponent(0.18)
        } else {
            .quaternaryLabelColor.withAlphaComponent(0.08)
        }
        layer?.backgroundColor = background.cgColor
        layer?.borderColor = NSColor.systemRed.cgColor
        layer?.borderWidth = isOverLimit && !isDropTarget ? 2 : 0
    }

    override var wantsUpdateLayer: Bool { true }
}

/// A Card on the Board: its title, and the start of its notes. Click to select
/// it, drag it to another Column to move it.
@MainActor
private final class CardView: NSView, NSDraggingSource {
    var onSelect: (() -> Void)?
    var onOpen: (() -> Void)?
    /// Offered only while the Card is editable: Done Cards can't be Discarded.
    var onDiscard: (() -> Void)?
    let card: Card
    var isSelected: Bool {
        didSet {
            needsDisplay = true
            setAccessibilitySelected(isSelected)
        }
    }
    private let isEditable: Bool
    /// Opens the edit sheet. Shown only while the pointer is over the Card.
    private let pencil = NSButton()
    private var isHovered = false {
        didSet { updatePencil() }
    }

    init(card: Card, in column: Column, isSelected: Bool) {
        self.card = card
        self.isSelected = isSelected
        isEditable = column != .done
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 8
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        let ageText = card.ageLabel(in: column)
        setAccessibilityLabel(ageText.map { "\(card.title), \($0)" } ?? card.title)
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
        if let ageText {
            let age = NSTextField(labelWithString: ageText)
            age.font = .monospacedDigitSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .caption1).pointSize, weight: .medium)
            age.textColor = .secondaryLabelColor
            age.alignment = .right
            age.isSelectable = false
            stack.addArrangedSubview(age)
        }
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        // Editable Cards keep room on the right so the pencil never covers text.
        let trailing: CGFloat = isEditable ? 30 : 10
        stack.edgeInsets = NSEdgeInsets(top: 8, left: 10, bottom: 8, right: trailing)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        for label in stack.arrangedSubviews {
            label.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -10 - trailing).isActive = true
        }

        if isEditable {
            pencil.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: "Edit")
            pencil.isBordered = false
            pencil.bezelStyle = .accessoryBarAction
            pencil.contentTintColor = .secondaryLabelColor
            pencil.toolTip = "Edit (Return)"
            pencil.target = self
            pencil.action = #selector(openFromPencil(_:))
            pencil.translatesAutoresizingMaskIntoConstraints = false
            addSubview(pencil)
            NSLayoutConstraint.activate([
                pencil.topAnchor.constraint(equalTo: topAnchor, constant: 6),
                pencil.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            ])
            updatePencil()
        }
    }

    private func updatePencil() {
        pencil.isHidden = !isHovered
    }

    @objc private func openFromPencil(_ sender: Any?) {
        onOpen?()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        guard isEditable else { return }
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                                       owner: self, userInfo: nil))
        // A Card rebuilt under a still pointer (after a move, an edit or the minute
        // refresh) gets no mouseEntered, so check where the pointer is now.
        if let window, window.isKeyWindow {
            isHovered = bounds.contains(convert(window.mouseLocationOutsideOfEventStream, from: nil))
        }
    }

    override func mouseEntered(with event: NSEvent) { isHovered = true }
    override func mouseExited(with event: NSEvent) { isHovered = false }

    override func menu(for event: NSEvent) -> NSMenu? {
        onSelect?()
        let menu = NSMenu()
        menu.addItem(withTitle: isEditable ? "Edit…" : "Open…", action: #selector(openFromPencil(_:)), keyEquivalent: "").target = self
        if isEditable {
            menu.addItem(.separator())
            menu.addItem(withTitle: "Discard", action: #selector(discardFromMenu(_:)), keyEquivalent: "").target = self
        }
        return menu
    }

    @objc private func discardFromMenu(_ sender: Any?) {
        onDiscard?()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// The whole Card is one target, apart from its pencil: clicks and drags on
    /// its labels select or drag the Card, and the labels show no text cursor.
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard frame.contains(point) else { return nil }
        if !pencil.isHidden, pencil.frame.contains(convert(point, from: superview)) { return pencil }
        return self
    }

    override func mouseDown(with event: NSEvent) {
        onSelect?()
        if event.clickCount == 2 { onOpen?() }
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

    // Called with the view's appearance current, so the system colours resolve
    // for light or dark before they're mixed.
    override func updateLayer() {
        let urgency = CGFloat(card.urgency)
        let tint = Self.tint(for: urgency)
        layer?.backgroundColor = Self.mix(.controlBackgroundColor, tint, urgency * 0.45).cgColor
        let border = isSelected ? NSColor.controlAccentColor : Self.mix(.separatorColor, tint, urgency)
        layer?.borderColor = border.cgColor
        layer?.borderWidth = isSelected ? 2 : 1
    }

    /// Amber, turning red over the second half of the Urgency range.
    private static func tint(for urgency: CGFloat) -> NSColor {
        mix(.systemOrange, .systemRed, max(0, urgency - 0.5) * 2)
    }

    private static func mix(_ base: NSColor, _ other: NSColor, _ fraction: CGFloat) -> NSColor {
        guard let base = base.usingColorSpace(.sRGB), let other = other.usingColorSpace(.sRGB) else { return base }
        return base.blended(withFraction: fraction, of: other) ?? base
    }

    override var wantsUpdateLayer: Bool { true }
}

/// Lays the Cards out from the top of the scroll view, not the bottom.
private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

private extension Card {
    /// "12d" in Backlog, "4d in Doing" in Doing, hours under a day; none in Done.
    func ageLabel(in column: Column) -> String? {
        guard let age else { return nil }
        let text = switch age {
        case ..<3_600: "<1h"
        case ..<86_400: "\(Int(age / 3_600))h"
        default: "\(Int(age / 86_400))d"
        }
        return column == .doing ? "\(text) in Doing" : text
    }
}
