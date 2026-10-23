import AppKit
import KanbanCore

/// The three Columns side by side, each listing its Cards.
@MainActor
final class BoardViewController: NSViewController {
    private let board: Board
    private let columnViews = Column.allCases.map { ColumnView(column: $0) }

    init(board: Board) {
        self.board = board
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func loadView() {
        let columns = NSStackView(views: columnViews)
        columns.orientation = .horizontal
        columns.distribution = .fillEqually
        columns.alignment = .top
        columns.spacing = 12
        columns.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        for view in columnViews {
            view.heightAnchor.constraint(equalTo: columns.heightAnchor, constant: -32).isActive = true
        }
        view = columns
        reload()
    }

    func reload() {
        do {
            for view in columnViews {
                view.show(try board.cards(in: view.column))
            }
        } catch {
            presentError(error)
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
}

/// One Column: its title above its Cards, which scroll when they don't fit.
@MainActor
private final class ColumnView: NSView {
    let column: Column
    private let cards = NSStackView()

    init(column: Column) {
        self.column = column
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 10
        setAccessibilityLabel(column.title)

        let title = NSTextField(labelWithString: column.title)
        title.font = .preferredFont(forTextStyle: .headline)
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)

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
            title.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
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

    func show(_ cards: [Card]) {
        for view in self.cards.arrangedSubviews { view.removeFromSuperview() }
        for card in cards {
            let view = CardView(card: card)
            self.cards.addArrangedSubview(view)
            view.widthAnchor.constraint(equalTo: self.cards.widthAnchor, constant: -24).isActive = true
        }
    }

    // A layer colour doesn't follow appearance changes on its own.
    override func updateLayer() {
        layer?.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.08).cgColor
    }

    override var wantsUpdateLayer: Bool { true }
}

/// A Card on the Board: its title, and the start of its notes.
@MainActor
private final class CardView: NSView {
    init(card: Card) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 8
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel(card.title)

        let title = NSTextField(wrappingLabelWithString: card.title)
        title.font = .preferredFont(forTextStyle: .body)
        let stack = NSStackView(views: [title])
        if !card.notes.isEmpty {
            let notes = NSTextField(wrappingLabelWithString: card.notes)
            notes.font = .preferredFont(forTextStyle: .callout)
            notes.textColor = .secondaryLabelColor
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

    override func updateLayer() {
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.borderWidth = 1
    }

    override var wantsUpdateLayer: Bool { true }
}

/// Lays the Cards out from the top of the scroll view, not the bottom.
private final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
