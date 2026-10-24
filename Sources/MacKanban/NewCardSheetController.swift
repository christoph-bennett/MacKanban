import AppKit
import KanbanCore

/// The New Card sheet behind its creation gate (spec 0001): open goes straight
/// to title and notes, Triage first asks about the most urgent Open Card, and
/// blocked only explains. AppKit for the same reason as `CardSheetViewController`.
@MainActor
final class NewCardSheetController: NSViewController {
    /// Start, Discard or Keep, or Dismissed when the sheet is closed at Triage.
    /// Throwing keeps the sheet at Triage, with the error shown.
    var onTriage: ((TriageOutcome) throws -> Void)?
    /// Called with the title and notes; throwing keeps the sheet open.
    var onSave: ((_ title: String, _ notes: String) throws -> Void)?

    private let gate: CreationGate
    /// The triaged Card's Column (Triage can show a Card in Doing).
    private let column: Column
    private let capacity: Capacity
    /// Why Start is unavailable, if it is: Doing at its WIP Limit, or the Card already there.
    private let startRefusal: BoardError?
    private var isAtTriage = false

    init(gate: CreationGate, column: Column = .backlog, capacity: Capacity, startRefusal: BoardError?) {
        self.gate = gate
        self.column = column
        self.capacity = capacity
        self.startRefusal = startRefusal
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func loadView() {
        view = NSView()
        switch gate {
        case .open: showCardStep()
        case let .triage(card): show(triageStep(for: card))
        case let .blocked(capacity, openCards, cardsToFree):
            show(blockedStep(BoardError.creationBlocked(capacity: capacity, openCards: openCards, cardsToFree: cardsToFree)))
        }
    }

    /// Esc at Triage or blocked; the title-and-notes step handles its own.
    override func cancelOperation(_ sender: Any?) {
        close(nil)
    }

    @objc private func close(_ sender: Any?) {
        if isAtTriage {
            isAtTriage = false
            // Closing the sheet is a decision too; if it can't be recorded, closing still wins.
            do { try onTriage?(.dismissed) } catch { NSLog("MacKanban: Triage not recorded: \(error)") }
        }
        dismiss(nil)
    }

    // MARK: Triage

    private func triageStep(for card: Card) -> NSView {
        isAtTriage = true
        let heading = NSTextField(labelWithString: "Before you add a Card")
        heading.font = .preferredFont(forTextStyle: .headline)
        let reason = NSTextField(wrappingLabelWithString: card.urgency >= 1 && capacity.free > CreationGate.triageThreshold
            ? "Your most urgent Card is fully red. Decide about it first."
            : "Capacity is nearly used up: \(capacity.free) of \(capacity.total) free. Decide about your most urgent Card first.")

        let start = NSButton(title: "Start", target: self, action: #selector(start(_:)))
        let discard = NSButton(title: "Discard", target: self, action: #selector(discard(_:)))
        let keep = NSButton(title: "Keep", target: self, action: #selector(keep(_:)))
        let cancel = NSButton(title: "Cancel", target: self, action: #selector(close(_:)))
        cancel.keyEquivalent = "\u{1b}"
        keep.toolTip = "Leave it where it is. Its Urgency stays as it is."
        if startRefusal == nil {
            start.keyEquivalent = "\r"
        } else {
            start.isEnabled = false
        }
        let buttons = NSStackView(views: [cancel, NSView(), discard, keep, start])
        buttons.orientation = .horizontal

        var views: [NSView] = [heading, reason, TriagedCardView(card: card, in: column), buttons]
        if let startRefusal {
            let why = NSTextField(wrappingLabelWithString: startRefusal.localizedDescription)
            why.textColor = .secondaryLabelColor
            why.font = .preferredFont(forTextStyle: .callout)
            views.append(why)
        }
        return stack(views)
    }

    @objc private func start(_ sender: Any?) { decide(.started) }
    @objc private func discard(_ sender: Any?) { decide(.discarded) }
    @objc private func keep(_ sender: Any?) { decide(.kept) }

    private func decide(_ outcome: TriageOutcome) {
        do {
            try onTriage?(outcome)
        } catch {
            presentError(error)
            return
        }
        isAtTriage = false
        showCardStep()
    }

    // MARK: Blocked

    private func blockedStep(_ reason: BoardError) -> NSView {
        let heading = NSTextField(labelWithString: "No room for a new Card")
        heading.font = .preferredFont(forTextStyle: .headline)
        let explanation = NSTextField(wrappingLabelWithString: reason.localizedDescription)
        let detail = NSTextField(wrappingLabelWithString:
            "Capacity grows as you finish Cards and shrinks as Open Cards age.")
        detail.textColor = .secondaryLabelColor
        detail.font = .preferredFont(forTextStyle: .callout)
        let ok = NSButton(title: "OK", target: self, action: #selector(close(_:)))
        ok.keyEquivalent = "\r"
        let buttons = NSStackView(views: [NSView(), ok])
        buttons.orientation = .horizontal
        return stack([heading, explanation, detail, buttons])
    }

    // MARK: Title and notes

    private func showCardStep() {
        let sheet = CardSheetViewController(mode: .new)
        sheet.onSave = { [weak self] title, notes in
            guard let self else { return }
            do {
                try onSave?(title, notes)
                dismiss(nil)
            } catch {
                presentError(error)
            }
        }
        children.forEach { $0.removeFromParent() }
        addChild(sheet)
        show(sheet.view)
    }

    // MARK: Layout

    private func stack(_ views: [NSView]) -> NSView {
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        for view in views {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        }
        stack.widthAnchor.constraint(equalToConstant: 400).isActive = true
        return stack
    }

    /// Replaces the sheet's content with `step` and fits the sheet to it.
    private func show(_ step: NSView) {
        view.subviews.forEach { $0.removeFromSuperview() }
        step.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(step)
        NSLayoutConstraint.activate([
            step.topAnchor.constraint(equalTo: view.topAnchor),
            step.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            step.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            step.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        guard let window = view.window else { return }  // the first step, before the sheet is up
        view.layoutSubtreeIfNeeded()
        window.setContentSize(view.fittingSize)
        if let title = step.firstKeyView(ofType: NSTextField.self) { window.makeFirstResponder(title) }
    }
}

private extension NSView {
    /// The first editable text field in this view's subtree.
    func firstKeyView(ofType type: NSTextField.Type) -> NSTextField? {
        if let field = self as? NSTextField, field.isEditable { return field }
        for view in subviews {
            if let field = view.firstKeyView(ofType: type) { return field }
        }
        return nil
    }
}

/// The triaged Card as it looks on the Board: tinted by its Urgency, with its age.
private final class TriagedCardView: NSView {
    private let urgency: Double

    init(card: Card, in column: Column) {
        urgency = card.urgency
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.borderWidth = 1

        let title = NSTextField(wrappingLabelWithString: card.title)
        title.font = .boldSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize)
        var views: [NSView] = [title]
        if !card.notes.isEmpty {
            let notes = NSTextField(wrappingLabelWithString: card.notes)
            notes.font = .preferredFont(forTextStyle: .callout)
            notes.textColor = .secondaryLabelColor
            notes.maximumNumberOfLines = 3
            notes.lineBreakMode = .byTruncatingTail
            views.append(notes)
        }
        if let age = card.ageLabel(in: column) {
            let label = NSTextField(labelWithString: column == .doing ? age : "\(age), in Backlog")
            label.font = .monospacedDigitSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .caption1).pointSize, weight: .medium)
            label.textColor = .secondaryLabelColor
            views.append(label)
        }
        let stack = NSStackView(views: views)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4
        stack.edgeInsets = NSEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        for view in views {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -24).isActive = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override var wantsUpdateLayer: Bool { true }

    override func updateLayer() {
        layer?.backgroundColor = UrgencyTint.background(for: urgency).cgColor
        layer?.borderColor = UrgencyTint.border(for: urgency).cgColor
    }
}
