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
    /// After every reload, for the toolbar's Capacity gauge and the menu bar extra.
    var onStateChange: ((BoardState) -> Void)?
    /// The age label on every Card (a setting, on by default). Tints show either way.
    var showsAges = true {
        didSet { if isViewLoaded { reload() } }
    }

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
            view.dropRefusal = { [weak self] card, column in try? self?.board.moveRefusal(card, to: column) }
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
            let state = try board.state()
            let columns = state.columns
            // A Card that left the Board (Discarded, or an undone creation) can't stay selected.
            if let selectedCard, !columns.values.contains(where: { $0.contains { $0.id == selectedCard } }) {
                self.selectedCard = nil
            }
            for view in columnViews {
                view.show(columns[view.column] ?? [], selected: selectedCard, showsAges: showsAges)
            }
            let wip = WIPStatus(count: columns[.doing]?.count ?? 0, limit: board.wipLimit)
            columnViews.first { $0.column == .doing }?.showCount("\(wip.count) / \(wip.limit)", isWarning: wip.isOverLimit)
            onStateChange?(state)
        } catch {
            show(error)
        }
    }

    /// The New Card sheet, behind the creation gate: a blocked attempt is recorded
    /// as it opens, and a Triage start or Discard can be undone on its own.
    func newCard() {
        guard !isShowingSheet else { return }
        let sheet: NewCardSheetController
        do {
            let gate = try board.attemptCreation()
            var column = Column.backlog
            var startRefusal: BoardError?
            if case let .triage(card) = gate {
                if try board.cards(in: .doing).contains(where: { $0.id == card.id }) { column = .doing }
                startRefusal = try board.moveRefusal(card.id, to: .doing)
                sheet = NewCardSheetController(gate: gate, column: column, capacity: try board.capacity(), startRefusal: startRefusal)
                sheet.onTriage = { [weak self] outcome in try self?.triage(card.id, outcome) }
            } else {
                sheet = NewCardSheetController(gate: gate, capacity: try board.capacity(), startRefusal: nil)
            }
        } catch {
            return show(error)
        }
        sheet.onSave = { [weak self] title, notes in
            guard let self else { return }
            let id = UUID()  // kept for redo, so later redos still find the Card
            do {
                try undoably("New Card") { [board] in try board.createCard(title: title, notes: notes, id: id) }
            } catch let error as BoardError {
                // Blocked while the sheet was open: an attempt like any other, so it's recorded.
                if case .creationBlocked = error { _ = try? board.attemptCreation() }
                throw error
            }
            reload()
        }
        presentAsSheet(sheet)
    }

    private func triage(_ id: UUID, _ outcome: TriageOutcome) throws {
        switch outcome {
        case .started, .discarded:
            try undoably(outcome == .started ? "Start" : "Discard") { [board] in
                // Redo records the Triage again, so its undo removes both events again.
                guard let change = try board.triage(id, outcome: outcome) else { throw BoardError.cannotUndo }
                return change
            }
        case .kept, .dismissed:
            try board.triage(id, outcome: outcome)
        }
        reload()
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
            try undoably("Discard") { [board] in try board.discard(id) }
            if selectedCard == id { selectedCard = nil }
            reload()
        } catch {
            show(error)
        }
    }

    /// Moves a Doing Card to Done from the menu bar extra, undoable in the Board window.
    /// Leaves the selection alone: the user didn't pick the Card here. Refused
    /// while a sheet is up, which may be about this very Card (Triage, editing):
    /// the window comes forward to show it.
    func finish(_ id: UUID) {
        guard !isShowingSheet else {
            view.window?.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return NSSound.beep()
        }
        do {
            try undoably("Move") { [board] in try board.move(id, to: .done) }
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
            try undoably("Move") { [board] in try board.move(card, to: column) }
            selectedCard = card
            reload()
        } catch {
            show(error)
        }
    }

    // MARK: Undo

    /// Runs `operation` and registers its undo with the window. Undo reverts what it
    /// recorded (the Board deletes the events, ADR 0002); redo runs it again.
    private func undoably(_ actionName: String, _ operation: @escaping () throws -> Change) throws {
        let change = try operation()
        guard let undoManager = view.window?.undoManager else { return }
        undoManager.registerUndo(withTarget: self) { controller in
            controller.undo(change, actionName: actionName, redo: operation)
        }
        undoManager.setActionName(actionName)
    }

    private func undo(_ change: Change, actionName: String, redo: @escaping () throws -> Change) {
        do {
            try board.revert(change)
        } catch {
            return show(error)
        }
        reload()
        guard let undoManager = view.window?.undoManager else { return }
        undoManager.registerUndo(withTarget: self) { controller in
            do {
                try controller.undoably(actionName, redo)
                controller.reload()
            } catch {
                controller.show(error)
            }
        }
        undoManager.setActionName(actionName)
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

    /// A refused move or a store error, as a sheet on the Board window, or as
    /// an alert of its own while the window is hidden (from the menu bar extra).
    private func show(_ error: Error) {
        if let window = view.window, window.isVisible {
            NSAlert(error: error).beginSheetModal(for: window)
        } else {
            NSApp.activate()  // from the menu bar extra, another app may be in front
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
    /// Why dropping the Card here would be refused, asked while it's dragged over.
    var dropRefusal: ((_ card: UUID, _ column: Column) -> BoardError?)?
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
    /// A Card dragged over a Column that won't take it: shown in the over-limit red, and the drop is refused.
    private var isRefusingDrop = false {
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
        // 4 pt on top so the first Card's hover growth isn't clipped by the scroll view.
        cards.edgeInsets = NSEdgeInsets(top: 4, left: 12, bottom: 12, right: 12)
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
            scroll.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),  // + the 4 pt inset: 8 pt to the first Card
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

    func show(_ cards: [Card], selected: UUID?, showsAges: Bool) {
        for view in self.cards.arrangedSubviews { view.removeFromSuperview() }
        for card in cards {
            let view = CardView(card: card, in: column, isSelected: card.id == selected, showsAge: showsAges)
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
    /// A drop the Board would refuse (a full Doing, Backlog → Done, out of Done) is
    /// refused here, in red, rather than explained afterwards; the Card goes back
    /// where it came from. Keyboard moves still explain in a sheet.
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let card = Self.card(in: sender), !contains(card) else { return [] }
        if dropRefusal?(card, column) != nil {
            isRefusingDrop = true
            return []
        }
        isDropTarget = true
        return .move
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDropTarget = false
        isRefusingDrop = false
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        isDropTarget = false
        isRefusingDrop = false
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
        let showsRed = isRefusingDrop || (isOverLimit && !isDropTarget)
        let background: NSColor = if showsRed {
            .systemRed.withAlphaComponent(0.18)
        } else if isDropTarget {
            .controlAccentColor.withAlphaComponent(0.15)
        } else {
            .quaternaryLabelColor.withAlphaComponent(0.08)
        }
        layer?.backgroundColor = background.cgColor
        layer?.borderColor = NSColor.systemRed.cgColor
        layer?.borderWidth = showsRed ? 2 : 0
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
        didSet {
            updatePencil()
            if isHovered != oldValue { updateGrowth(animated: true) }
        }
    }

    /// - Parameter showsAge: the age label; its line stays either way, and
    ///   VoiceOver reads the age either way.
    init(card: Card, in column: Column, isSelected: Bool, showsAge: Bool) {
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
        var ageLabel: NSTextField?
        if let ageText {
            let age = NSTextField(labelWithString: ageText)
            ageLabel = age
            // Hidden ages keep their line, so switching them off doesn't shrink Cards.
            // Transparent rather than `isHidden`, which the stack would collapse.
            if !showsAge {
                age.alphaValue = 0
                age.setAccessibilityElement(false)  // the Card's own label has the age
            }
            age.font = .monospacedDigitSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .caption1).pointSize, weight: .medium)
            age.textColor = .secondaryLabelColor
            age.alignment = .right
            age.isSelectable = false
            stack.addArrangedSubview(age)
        }
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.edgeInsets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        // On editable Cards the title and notes keep room for the pencil at the top
        // right; the age label sits below it and runs to the edge.
        for label in stack.arrangedSubviews {
            let pencilRoom: CGFloat = isEditable && label !== ageLabel ? 20 : 0
            label.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -20 - pencilRoom).isActive = true
        }

        if isEditable {
            // An accessory button (HIG audit, finding 1): a rounded highlight under the
            // pointer and a press state, with room around the symbol to click.
            pencil.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: "Edit")?
                .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 12, weight: .medium))
            pencil.bezelStyle = .accessoryBarAction
            pencil.isBordered = true
            pencil.showsBorderOnlyWhileMouseInside = true
            pencil.imagePosition = .imageOnly
            pencil.contentTintColor = .secondaryLabelColor
            pencil.toolTip = "Edit (Return)"
            pencil.target = self
            pencil.action = #selector(openFromPencil(_:))
            pencil.translatesAutoresizingMaskIntoConstraints = false
            addSubview(pencil)
            NSLayoutConstraint.activate([
                pencil.topAnchor.constraint(equalTo: topAnchor, constant: 4),
                pencil.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
                pencil.widthAnchor.constraint(equalToConstant: 22),
                pencil.heightAnchor.constraint(equalToConstant: 22),
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
        // Every Card grows under the pointer; only editable ones have the pencil.
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                                       owner: self, userInfo: nil))
        // A Card rebuilt under a still pointer (after a move, an edit or the minute
        // refresh) gets no mouseEntered, so check where the pointer is now.
        if let window, window.isKeyWindow {
            isHovered = bounds.contains(convert(window.mouseLocationOutsideOfEventStream, from: nil))
        }
    }

    /// How far the hovered Card grows on every side.
    private static let hoverGrowth: CGFloat = 2

    /// Grows the Card a little under the pointer, around its centre, in a short
    /// animation; at once with Reduce Motion. A layer transform, so the Columns'
    /// layout doesn't move.
    private func updateGrowth(animated: Bool) {
        guard let layer, bounds.width > 0, bounds.height > 0 else { return }
        var target = CATransform3DIdentity
        if isHovered {
            let (cx, cy) = (bounds.midX, bounds.midY)
            target = CATransform3DMakeTranslation(cx, cy, 0)
            target = CATransform3DScale(target, 1 + 2 * Self.hoverGrowth / bounds.width,
                                        1 + 2 * Self.hoverGrowth / bounds.height, 1)
            target = CATransform3DTranslate(target, -cx, -cy, 0)
        }
        if animated, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            let animation = CABasicAnimation(keyPath: "transform")
            animation.fromValue = layer.presentation()?.transform ?? layer.transform
            animation.toValue = target
            animation.duration = 0.12
            animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            layer.add(animation, forKey: "hoverGrowth")
        }
        layer.transform = target
    }

    /// Keeps the growth right for the Card's size, e.g. while the window resizes.
    override func layout() {
        super.layout()
        if isHovered { updateGrowth(animated: false) }
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
        layer?.backgroundColor = UrgencyTint.background(for: card.urgency).cgColor
        let border = isSelected ? NSColor.controlAccentColor : UrgencyTint.border(for: card.urgency)
        layer?.borderColor = border.cgColor
        layer?.borderWidth = isSelected ? 2 : 1
    }

    override var wantsUpdateLayer: Bool { true }
}

/// Lays the Cards out from the top of the scroll view, not the bottom.
private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

/// A Card's colours for its Urgency, for the Board and the Triage sheet. Resolve
/// them with the view's appearance current, so system colours mix for light or dark.
enum UrgencyTint {
    static func background(for urgency: Double) -> NSColor {
        mix(.controlBackgroundColor, tint(for: urgency), urgency * 0.45)
    }

    static func border(for urgency: Double) -> NSColor {
        mix(.separatorColor, tint(for: urgency), urgency)
    }

    /// Amber, turning red over the second half of the Urgency range.
    private static func tint(for urgency: Double) -> NSColor {
        mix(.systemOrange, .systemRed, max(0, urgency - 0.5) * 2)
    }

    private static func mix(_ base: NSColor, _ other: NSColor, _ fraction: Double) -> NSColor {
        guard let base = base.usingColorSpace(.sRGB), let other = other.usingColorSpace(.sRGB) else { return base }
        return base.blended(withFraction: fraction, of: other) ?? base
    }
}

extension Card {
    /// "12d old" in Backlog (Card Age), "4d in Doing" in Doing (Column Age), hours
    /// under a day; none in Done. Each names what it measures: a Card that spent
    /// most of its life in Doing shows nearly the same number in both.
    func ageLabel(in column: Column) -> String? {
        guard let age else { return nil }
        let text = switch age {
        case ..<3_600: "<1h"
        case ..<86_400: "\(Int(age / 3_600))h"
        default: "\(Int(age / 86_400))d"
        }
        return column == .doing ? "\(text) in Doing" : "\(text) old"
    }
}
