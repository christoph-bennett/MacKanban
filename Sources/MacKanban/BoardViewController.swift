import AppKit
import KanbanCore

/// The three Columns side by side, each listing its Cards. A clicked Card is
/// selected, and a click anywhere else on the Board clears the selection;
/// ⌘→ and ⌘← (the Card menu) or dragging move it between Columns.
/// Its pencil, a double-click or Return opens it; ⌘⌫ or its context menu Discards
/// it, or archives it if it's a Done Card (spec 0003).
/// Esc closes the window; the selection is still there when it comes back.
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
            view.onArchive = { [weak self] card in self?.archive(card) }
            view.onArchiveAll = { [weak self] in self?.archiveAllDoneCards(nil) }
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
            let wip = WIPStatus(count: columns[.doing]?.count ?? 0, limit: board.wipLimit)
            for view in columnViews {
                let cards = columns[view.column] ?? []
                view.show(cards, selected: selectedCard, showsAges: showsAges)
                switch view.column {
                case .doing:
                    view.showCount("\(wip.count) / \(wip.limit)", isWarning: wip.isOverLimit)
                case .backlog:
                    // The room the Capacity leaves beside Doing. Never red: over it, creating is
                    // blocked, and the Capacity gauge already says so.
                    let room = state.roomForBacklog
                    view.showCount("\(cards.count) / \(room)", spoken: "\(cards.count) of \(room) Cards", isWarning: false)
                case .done:
                    // No limit: just how many Cards are in it, without the Archive.
                    view.showCount("\(cards.count)", spoken: cards.count == 1 ? "1 Card" : "\(cards.count) Cards", isWarning: false)
                }
            }
            onStateChange?(state)
        } catch {
            show(error)
        }
    }

    /// The New Card sheet, behind the creation gate: a blocked attempt is recorded
    /// as it opens, and a Triage start or Discard can be undone on its own. Nothing
    /// opens while another sheet (or an alert) is on the Board.
    /// - Parameter handingBackOnClose: once the sheet closes, saved or not, the
    ///   Board closes as with Esc (the New Card hotkey, pressed in another app).
    func newCard(handingBackOnClose: Bool = false) {
        guard !isShowingSheet, view.window?.attachedSheet == nil else { return }
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
        if handingBackOnClose { handsBackAfter = sheet }
        presentAsSheet(sheet)
    }

    /// The New Card sheet whose closing also closes the Board (New Card hotkey).
    private weak var handsBackAfter: NSViewController?

    /// Every sheet ends here, saved or not, also the New Card sheet's title-and-notes
    /// step (it dismisses its parent). Hiding the app doesn't, so ⌘H keeps the hand-back.
    override func dismiss(_ viewController: NSViewController) {
        super.dismiss(viewController)
        guard viewController === handsBackAfter else { return }
        handsBackAfter = nil
        // After the sheet has left the window: a window with a sheet won't close.
        DispatchQueue.main.async { [weak self] in self?.closeAndHandBack(nil) }
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
    /// Sample Cards don't open: they can't be edited, and the Card shows all they hold.
    private func open(_ id: UUID) {
        guard let (card, column) = cardOnScreen(id) else { return }
        select(id)
        guard !card.isSample else { return }
        if column == .done {
            assert(card.doneSince != nil, "a Done Card on the Board has a Done date")
            presentCardSheet(.done(card, on: card.doneSince ?? .now, archived: false))
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
        takeOffBoard("Discard") { [board] in try board.discard(id) }
    }

    /// Sends a Done Card to the Archive before the Archive Delay is up (ADR 0007).
    private func archive(_ id: UUID) {
        takeOffBoard("Archive") { [board] in try board.archiveCard(id) }
    }

    /// Clears Done in one go, without asking: one ⌘Z brings every Card back.
    @objc func archiveAllDoneCards(_ sender: Any?) {
        takeOffBoard("Archive All") { [board] in try board.archiveAllDoneCards() }
    }

    /// Discard or Archive, from ⌘⌫ or a context menu; never while a sheet is open,
    /// as the Card menu's item is disabled then. The reload drops the selection.
    private func takeOffBoard(_ actionName: String, _ operation: @escaping () throws -> Change) {
        guard !isShowingSheet else { return }
        do {
            try undoably(actionName, operation)
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
            NSApp.activateAsAsked()  // from the menu bar extra
            return NSSound.beep()
        }
        do {
            try undoably("Move") { [board] in try board.move(id, to: .done) }
            reload()
        } catch {
            show(error)
        }
    }

    // MARK: Sample Cards

    /// The first-launch offer of Sample Cards (ADR 0005), as a sheet on the window;
    /// only to a Board that never had a Card. Returns whether the offer is settled:
    /// shown now, or never due because the Board has Cards. `false` (no window, a
    /// sheet up, a store error) leaves it for the next launch.
    func offerSampleCards() -> Bool {
        guard let window = view.window, !isShowingSheet, window.attachedSheet == nil,
              let hasCards = try? board.hasCards()
        else { return false }
        guard !hasCards else { return true }
        let alert = NSAlert()
        alert.messageText = "Try MacKanban with sample Cards?"
        alert.informativeText = "A few everyday chores of different ages show how Cards age and how the Board "
            + "limits new work. You can remove them anytime from the menu bar menu; your own Cards stay."
        alert.addButton(withTitle: "Add Sample Cards")
        alert.addButton(withTitle: "Start Empty")
        alert.beginSheetModal(for: window) { [weak self] response in
            // The alert is still attached while this runs, so not `addSampleCards()`,
            // which refuses while a sheet is up.
            guard response == .alertFirstButtonReturn else { return }
            self?.insertSampleCards()
        }
        return true
    }

    func addSampleCards() {
        guard isFreeForSampleCards() else { return }
        insertSampleCards()
    }

    /// Adding can't be undone with ⌘Z: removing them is the way back. It clears the
    /// undo stack, so an undo from before can't reopen a Card next to them and
    /// spoil the Capacity they were chosen for.
    private func insertSampleCards() {
        do {
            try board.addSampleCards()
            view.window?.undoManager?.removeAllActions()
            reload()
        } catch {
            show(error)
        }
    }

    /// Asks first, since removing can't be undone. Clears the whole undo stack, which
    /// could otherwise try to restore an event of a Card that no longer exists: its
    /// entries don't say which Card they're about.
    func removeSampleCards() {
        guard isFreeForSampleCards(), let window = view.window else { return }
        let count: Int
        do {
            count = try board.sampleCardCount()
        } catch {
            return show(error)
        }
        guard count > 0 else { return }
        let alert = NSAlert()
        alert.messageText = "Remove \(count) sample Cards?"
        alert.informativeText = "Your own Cards stay. This can't be undone."
        alert.addButton(withTitle: "Remove Sample Cards")
        alert.addButton(withTitle: "Cancel")
        alert.beginSheetModal(for: window) { [weak self] response in
            guard let self, response == .alertFirstButtonReturn else { return }
            do {
                try board.removeSampleCards()
                view.window?.undoManager?.removeAllActions()
                reload()
            } catch {
                show(error)
            }
        }
    }

    /// Refused while a sheet is up, which may be about a Sample Card (Triage):
    /// the window comes forward to show it.
    private func isFreeForSampleCards() -> Bool {
        guard isShowingSheet || view.window?.attachedSheet != nil else { return true }
        view.window?.makeKeyAndOrderFront(nil)
        NSApp.activateAsAsked()  // from the menu bar extra
        NSSound.beep()
        return false
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

    /// Esc closes the Board window, a selected Card or not, and if no other MacKanban
    /// window is left, hides MacKanban so the app the user came from is in front again.
    /// A sheet or a drag takes Esc before this does.
    override func cancelOperation(_ sender: Any?) {
        closeAndHandBack(sender)
    }

    /// Esc's way out, also taken by the show-Board hotkey when the Board is in front.
    func closeAndHandBack(_ sender: Any?) {
        guard let window = view.window else { return }
        window.performClose(sender)
        guard !window.isVisible else { return }
        // A minimized Archive or Settings window still counts as open.
        let othersOpen = NSApp.windows.contains {
            $0 !== window && ($0.isVisible || $0.isMiniaturized) && $0.styleMask.contains(.titled) && !$0.isSheet
        }
        if !othersOpen { NSApp.hide(nil) }
    }

    @objc func editCard(_ sender: Any?) {
        selectedCard.map(open)
    }

    /// ⌘⌫: takes the selected Card off the Board. An Open Card is Discarded, a
    /// Done Card archived; the menu item's title says which.
    @objc func discardOrArchiveCard(_ sender: Any?) {
        guard let id = selectedCard else { return }
        selectedColumn == .done ? archive(id) : discard(id)
    }

    /// Only redraws the selection: rebuilding the Card views would replace the
    /// one being clicked, and a drag starting from it would have no window.
    /// `nil` clears it.
    private func select(_ card: UUID?) {
        selectedCard = card
        view.window?.makeFirstResponder(view)  // so the Card menu's shortcuts reach this controller
        for view in columnViews { view.select(card) }
    }

    /// A click on the Board that no Card took (an empty part of a Column, its
    /// header, the gaps and margins) comes up the responder chain to here and
    /// clears the selection. Cards handle their own clicks; the title bar isn't
    /// in this view.
    override func mouseDown(with event: NSEvent) {
        select(nil)
    }

    /// The same for a right click: the Board has no menu of its own there.
    override func rightMouseDown(with event: NSEvent) {
        select(nil)
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
            } catch BoardError.cardIsArchived, BoardError.nothingToArchive {
                controller.reload()  // redoing an archive after the Archive Delay took the Card(s) anyway
            } catch {
                controller.show(error)
            }
        }
        undoManager.setActionName(actionName)
    }

    private var selectedIsSample: Bool {
        selectedCard.flatMap(cardOnScreen)?.0.isSample ?? false
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
            menuItem.title = selectedColumn == .done ? "Open Card" : "Edit Card…"  // a Done Card only shows, so no "…"
        }
        if menuItem.action == #selector(discardOrArchiveCard(_:)) {
            menuItem.title = selectedColumn == .done ? "Archive Card" : "Discard Card"
        }
        if isShowingSheet,
           [#selector(moveToNextColumn(_:)), #selector(moveToPreviousColumn(_:)), #selector(editCard(_:)),
            #selector(discardOrArchiveCard(_:)), #selector(archiveAllDoneCards(_:))].contains(menuItem.action) {
            return false
        }
        return switch menuItem.action {
        case #selector(moveToNextColumn(_:)): column(by: 1) != nil
        case #selector(moveToPreviousColumn(_:)): column(by: -1) != nil
        case #selector(editCard(_:)): selectedColumn != nil && !selectedIsSample
        case #selector(discardOrArchiveCard(_:)): selectedColumn == .backlog || selectedColumn == .doing
            || (selectedColumn == .done && !selectedIsSample)
        case #selector(archiveAllDoneCards(_:)): (try? board.hasDoneCardsToArchive()) ?? false  // asks the store: Done on screen may be a minute old
        default: true
        }
    }

    /// A refused move or a store error, as a sheet on the Board window, or as
    /// an alert of its own while the window is hidden (from the menu bar extra).
    private func show(_ error: Error) {
        if let window = view.window, window.isVisible {
            NSAlert(error: error).beginSheetModal(for: window)
        } else {
            NSApp.activateAsAsked()  // from the menu bar extra, another app may be in front
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
    var onArchive: ((UUID) -> Void)?
    var onArchiveAll: (() -> Void)?
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
            view.onArchive = { [weak self] in self?.onArchive?(card.id) }
            view.onArchiveAll = { [weak self] in self?.onArchiveAll?() }
            view.onMove = { [weak self] column in self?.onDrop?(card.id, column) }  // same move as a drop
            self.cards.addArrangedSubview(view)
            view.widthAnchor.constraint(equalTo: self.cards.widthAnchor, constant: -24).isActive = true
        }
    }

    /// Text on the right of the Column's title: Doing's "2 / 3", Backlog's "5 / 10", Done's plain count.
    /// - Parameter spoken: what VoiceOver reads instead of `text`, if anything.
    func showCount(_ text: String, spoken: String? = nil, isWarning: Bool) {
        count.stringValue = text
        count.textColor = isWarning ? .systemRed : .secondaryLabelColor
        isOverLimit = isWarning
        let label = spoken ?? text
        count.setAccessibilityLabel(isWarning ? "\(label), over the WIP Limit" : label)
    }

    func contains(_ card: UUID?) -> Bool {
        card.map(cardIDs.contains) ?? false
    }

    func card(_ id: UUID) -> Card? {
        cards.arrangedSubviews.lazy.compactMap { ($0 as? CardView)?.card }.first { $0.id == id }
    }

    /// `nil` shows no Card as selected.
    func select(_ card: UUID?) {
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
            BoardColors.column
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
    /// Offered only for a Done Card that isn't a Sample Card (ADR 0007).
    var onArchive: (() -> Void)?
    /// Archive All Done Cards, offered beside Archive.
    var onArchiveAll: (() -> Void)?
    /// Moves the Card to the Column the context menu chose.
    var onMove: ((Column) -> Void)?
    let card: Card
    private let column: Column
    var isSelected: Bool {
        didSet {
            needsDisplay = true
            setAccessibilitySelected(isSelected)
        }
    }
    /// An Open Card: it can be Discarded, and edited unless it's a Sample Card.
    private let isEditable: Bool
    private var hasPencil: Bool { isEditable && !card.isSample }
    /// Opens the edit sheet. Shown only while the pointer is over the Card.
    private let pencil = PencilButton()
    private var isHovered = false {
        didSet {
            updatePencil()
            if isHovered != oldValue { updateGrowth(animated: true) }
        }
    }

    /// - Parameter showsAge: the age label; its line stays either way, and
    ///   VoiceOver reads the age either way. A Sample Card's line always shows
    ///   "Sample", with its age after it when ages are shown.
    init(card: Card, in column: Column, isSelected: Bool, showsAge: Bool) {
        self.card = card
        self.column = column
        self.isSelected = isSelected
        isEditable = column != .done
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 8
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        let ageText = card.ageLabel(in: column)
        let spokenAge = [card.isSample ? "sample" : nil, ageText].compactMap { $0 }.joined(separator: ", ")
        setAccessibilityLabel(spokenAge.isEmpty ? card.title : "\(card.title), \(spokenAge)")
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
        let lineText = card.isSample ? (showsAge ? ["Sample", ageText] : ["Sample"]).compactMap { $0 }.joined(separator: " · ") : ageText
        if let lineText {
            let age = NSTextField(labelWithString: lineText)
            ageLabel = age
            // Hidden ages keep their line, so switching them off doesn't shrink Cards.
            // Transparent rather than `isHidden`, which the stack would collapse.
            if !showsAge {
                if !card.isSample { age.alphaValue = 0 }  // "Sample" always shows
                age.setAccessibilityElement(false)  // the Card's own label has it
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
        // On Cards with a pencil the title and notes keep room for it at the top
        // right; the age label sits below it and runs to the edge.
        for label in stack.arrangedSubviews {
            let pencilRoom: CGFloat = hasPencil && label !== ageLabel ? 25 : 0  // to 6 pt left of the chip
            label.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -20 - pencilRoom).isActive = true
        }

        if hasPencil {
            pencil.image = NSImage(systemSymbolName: "pencil", accessibilityDescription: "Edit")?
                .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 12, weight: .medium))
            pencil.toolTip = "Edit (Return)"
            pencil.target = self
            pencil.action = #selector(openFromPencil(_:))
            pencil.translatesAutoresizingMaskIntoConstraints = false
            addSubview(pencil)
            NSLayoutConstraint.activate([
                // Clear of the Card's border, the same 7 pt from the top and the right
                // (decided 2026-10-24); 7 pt centres it on the title's first 16 pt line,
                // (10 + 8) − 11.
                pencil.topAnchor.constraint(equalTo: topAnchor, constant: 7),
                pencil.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -7),
                pencil.widthAnchor.constraint(equalToConstant: 22),
                pencil.heightAnchor.constraint(equalToConstant: 22),
            ])
            // A one-line title without notes would bring the age right under the
            // pencil; keep 6 pt. Always, hidden pencil or not, so hovering doesn't
            // change the Card's height.
            ageLabel?.topAnchor.constraint(greaterThanOrEqualTo: pencil.bottomAnchor, constant: 6).isActive = true
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

    /// A right click stays with the Card even when it has no menu (a Done Sample
    /// Card): passed on, it would reach the Board, which clears the selection.
    override func rightMouseDown(with event: NSEvent) {
        guard let menu = menu(for: event) else { return }  // selected either way
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        onSelect?()
        let menu = NSMenu()
        if !card.isSample {
            menu.addItem(withTitle: isEditable ? "Edit…" : "Open", action: #selector(openFromPencil(_:)), keyEquivalent: "").target = self
        }
        for target in Board.moveTargets(from: column) {
            let item = menu.addItem(withTitle: "Move to \(target.title)", action: #selector(moveFromMenu(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = target
        }
        if isEditable {
            menu.addItem(.separator())  // Discard apart from the rest
            menu.addItem(withTitle: "Discard", action: #selector(discardFromMenu(_:)), keyEquivalent: "").target = self
        } else if column == .done, !card.isSample {
            menu.addItem(.separator())  // where an Open Card has Discard
            menu.addItem(withTitle: "Archive", action: #selector(archiveFromMenu(_:)), keyEquivalent: "").target = self
            menu.addItem(withTitle: "Archive All Done Cards", action: #selector(archiveAllFromMenu(_:)), keyEquivalent: "").target = self
        }
        return menu.items.isEmpty ? nil : menu  // a Done Sample Card offers nothing
    }

    @objc private func discardFromMenu(_ sender: Any?) {
        onDiscard?()
    }

    @objc private func archiveFromMenu(_ sender: Any?) {
        onArchive?()
    }

    @objc private func archiveAllFromMenu(_ sender: Any?) {
        onArchiveAll?()
    }

    @objc private func moveFromMenu(_ sender: NSMenuItem) {
        guard let target = sender.representedObject as? Column else { return }
        onMove?(target)
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

/// The Card's edit button, shown while the pointer is over the Card: the pencil in
/// the text colour on a see-through neutral chip, a deeper shade of whatever colour
/// the Card has (grey on white, deeper amber or red on aging Cards). A fixed
/// colour clashed with one tint or another. The fill deepens under the pointer and while pressed (HIG: a
/// custom button needs a press state).
private final class PencilButton: NSButton {
    private var isPointerInside = false {
        didSet { updateFill() }
    }
    private var isPressed = false {
        didSet { updateFill() }
    }

    init() {
        super.init(frame: .zero)
        isBordered = false
        imagePosition = .imageOnly
        contentTintColor = .labelColor
        wantsLayer = true
        layer?.cornerRadius = 6
        updateFill()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    /// Its own area only: removing every tracking area also removed the one AppKit
    /// keeps for the hover text, so "Edit (Return)" never showed.
    private var pointerArea: NSTrackingArea?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let pointerArea { removeTrackingArea(pointerArea) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
                                  owner: self, userInfo: nil)
        addTrackingArea(area)
        pointerArea = area
    }

    override func mouseEntered(with event: NSEvent) { isPointerInside = true }
    override func mouseExited(with event: NSEvent) { isPointerInside = false }

    /// Called by the cell while the button is tracking a click.
    override func highlight(_ flag: Bool) {
        super.highlight(flag)
        isPressed = flag
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateFill()
    }

    override var isHidden: Bool {
        didSet { if isHidden { isPointerInside = false } }
    }

    /// Black over the Card in light mode, white in dark mode (a little stronger, as
    /// dark tints need more to show).
    private func updateFill() {
        let isDark = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let strength: CGFloat = isPressed ? 0.22 : isPointerInside ? 0.15 : 0.09
        let shade: NSColor = isDark ? .white : .black
        layer?.backgroundColor = shade.withAlphaComponent(isDark ? strength * 1.3 : strength).cgColor
    }
}

/// Lays the Cards out from the top of the scroll view, not the bottom.
private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

/// The Board's own colours, chosen by Christoph for light mode (2026-10-24), with
/// dark values keeping the same steps: the Column a recessed step darker than
/// the window, the Card border a soft line.
enum BoardColors {
    static let window = dynamic(light: 0xF1F6FC, dark: 0x262A2F)
    static let column = dynamic(light: 0xE7ECF0, dark: 0x1A1D21)
    /// Neutral Cards' border; aging Cards' borders shift from it toward their tint.
    static let cardBorder = dynamic(light: 0xDFE1E3, dark: 0x3A3E43)

    private static func dynamic(light: Int, dark: Int) -> NSColor {
        NSColor(name: nil) { appearance in
            rgb(appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light)
        }
    }

    private static func rgb(_ hex: Int) -> NSColor {
        NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

/// A Card's colours for its Urgency, for the Board and the Triage sheet. Resolve
/// them with the view's appearance current, so system colours mix for light or dark.
enum UrgencyTint {
    static func background(for urgency: Double) -> NSColor {
        mix(.controlBackgroundColor, tint(for: urgency), urgency * 0.45)
    }

    /// Rises steeply at first and is the full tint colour from Urgency 0.25 on, so a
    /// Card that has only just started aging shows it at the edge while its
    /// background stays nearly neutral.
    static func border(for urgency: Double) -> NSColor {
        mix(BoardColors.cardBorder, tint(for: urgency), min(1, 2 * urgency.squareRoot()))
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
    /// "12d old" in Backlog (Card Age), "4d in Doing" and "2d in Done" (Column Age),
    /// hours under a day. Each names what it measures: a Card that spent
    /// most of its life in Doing shows nearly the same number in both.
    func ageLabel(in column: Column) -> String? {
        guard let age else { return nil }
        let text = switch age {
        case ..<3_600: "<1h"
        case ..<86_400: "\(Int(age / 3_600))h"
        default: "\(Int(age / 86_400))d"
        }
        return switch column {
        case .backlog: "\(text) old"
        case .doing: "\(text) in Doing"
        case .done: "\(text) in Done"
        }
    }
}
