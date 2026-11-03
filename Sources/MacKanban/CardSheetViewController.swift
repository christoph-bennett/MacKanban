import AppKit
import KanbanCore

/// The Card sheet: a title (required) and optional notes, for a new Card, for
/// editing one, or read-only for a Done Card. AppKit rather than SwiftUI:
/// SwiftUI's `@State` is a macro whose plugin ships only with Xcode.
@MainActor
final class CardSheetViewController: NSViewController, NSTextFieldDelegate {
    enum Mode {
        case new
        case edit(Card)
        /// Done Cards stay as they were finished.
        case readOnly(Card)
        /// From the Archive: read-only too.
        case discarded(Card)
    }

    /// Called with the title and notes when the user adds or saves.
    var onSave: ((_ title: String, _ notes: String) -> Void)?

    private let mode: Mode
    private let titleField = NSTextField()
    private let notesView = NotesTextView()
    private let saveButton = NSButton(title: "", target: nil, action: nil)

    init(mode: Mode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    private var card: Card? {
        switch mode {
        case .new: nil
        case let .edit(card), let .readOnly(card), let .discarded(card): card
        }
    }

    private var isReadOnly: Bool {
        switch mode {
        case .readOnly, .discarded: true
        case .new, .edit: false
        }
    }

    override func loadView() {
        let headingText = switch mode {
        case .new: "New Card"
        case .edit: "Edit Card"
        case .readOnly: "Done Card"
        case .discarded: "Discarded Card"
        }
        let heading = NSTextField(labelWithString: headingText)
        heading.font = .preferredFont(forTextStyle: .headline)

        // Both fields labelled the same way (HIG audit, finding 8).
        let titleLabel = NSTextField(labelWithString: "Title")
        titleLabel.textColor = .secondaryLabelColor
        titleField.setAccessibilityTitleUIElement(titleLabel)  // VoiceOver: "Title"
        titleField.stringValue = card?.title ?? ""
        titleField.isEditable = !isReadOnly
        titleField.delegate = self

        let notesLabel = NSTextField(labelWithString: "Notes")
        notesLabel.textColor = .secondaryLabelColor
        notesView.setAccessibilityTitleUIElement(notesLabel)
        notesView.font = .preferredFont(forTextStyle: .body)
        notesView.string = card?.notes ?? ""
        notesView.isRichText = false
        notesView.allowsUndo = true
        notesView.isEditable = !isReadOnly
        notesView.textContainerInset = NSSize(width: 2, height: 4)
        let notesScroll = NSScrollView()
        notesScroll.documentView = notesView
        notesScroll.hasVerticalScroller = true
        notesScroll.borderType = .noBorder
        let notesBox = RoundedBox(around: notesScroll)
        notesView.autoresizingMask = [.width]
        notesView.isVerticallyResizable = true
        notesView.textContainer?.widthTracksTextView = true

        let buttons = NSStackView(views: [NSView()])
        buttons.orientation = .horizontal
        if isReadOnly {
            let close = NSButton(title: "Close", target: self, action: #selector(cancel(_:)))
            close.keyEquivalent = "\r"
            buttons.addArrangedSubview(close)
        } else {
            let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
            cancel.keyEquivalent = "\u{1b}"
            saveButton.title = card == nil ? "Add Card" : "Save"
            saveButton.target = self
            saveButton.action = #selector(save(_:))
            saveButton.keyEquivalent = "\r"
            updateSaveButton()
            buttons.addArrangedSubview(cancel)
            buttons.addArrangedSubview(saveButton)
        }

        let stack = NSStackView(views: [heading, titleLabel, titleField, notesLabel, notesBox, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.setCustomSpacing(4, after: titleLabel)  // a label sits with its field
        stack.setCustomSpacing(4, after: notesLabel)
        stack.setCustomSpacing(16, after: notesBox)
        for view in [titleField, notesBox, buttons] {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        }
        NSLayoutConstraint.activate([
            stack.widthAnchor.constraint(equalToConstant: 400),
            notesBox.heightAnchor.constraint(equalToConstant: 100),
        ])
        view = stack
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if !isReadOnly { view.window?.makeFirstResponder(titleField) }
    }

    func controlTextDidChange(_ notification: Notification) {
        updateSaveButton()
    }

    private func updateSaveButton() {
        saveButton.isEnabled = !titleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @objc private func save(_ sender: Any?) {
        guard saveButton.isEnabled else { return }
        onSave?(titleField.stringValue, notesView.string)
    }

    @objc private func cancel(_ sender: Any?) {
        close()
    }

    /// Esc closes the sheet in every mode, including read-only.
    override func cancelOperation(_ sender: Any?) {
        close()
    }

    /// The whole sheet, also when this is the title-and-notes step inside the
    /// New Card sheet.
    private func close() {
        (parent ?? self).dismiss(nil)
    }
}

/// The notes field: Return starts a new line here instead of pressing the
/// sheet's default button, which would save and close mid-sentence. Tab and
/// Shift-Tab move to the next and previous field, as in any Mac dialog;
/// ⌥Tab still types a tab.
private final class NotesTextView: NSTextView {
    override func insertTab(_ sender: Any?) {
        window?.selectNextKeyView(sender)
    }

    override func insertBacktab(_ sender: Any?) {
        window?.selectPreviousKeyView(sender)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let isPlainReturn = (event.keyCode == 36 || event.keyCode == 76)
            && event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty
        guard isPlainReturn, window?.firstResponder === self, isEditable else {
            return super.performKeyEquivalent(with: event)
        }
        insertNewline(nil)
        return true
    }
}

/// The notes box, with the rounded border of the title field above it rather than
/// the older square bezel. The border is on this container: drawn on the scroll
/// view's own layer, its clip view covers it.
private final class RoundedBox: NSView {
    init(around content: NSView) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 1),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override var wantsUpdateLayer: Bool { true }

    // Called with the view's appearance current, so the colour resolves for light or dark.
    override func updateLayer() {
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
    }
}
