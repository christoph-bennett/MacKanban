import AppKit
import KanbanCore

/// The Card sheet: a title (required) and optional notes, for a new Card or
/// for editing one; or, for a Done or Discarded Card, read-only, shown as text
/// rather than fields (MVP ticket 19, after the HIG). AppKit rather than
/// SwiftUI: SwiftUI's `@State` is a macro whose plugin ships only with Xcode.
@MainActor
final class CardSheetViewController: NSViewController, NSTextFieldDelegate {
    enum Mode {
        case new
        case edit(Card)
        /// Done Cards stay as they were finished: on the Board, or archived.
        case done(Card, on: Date, archived: Bool)
        /// From the Archive: read-only too.
        case discarded(Card, on: Date)
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
        case let .edit(card), let .done(card, _, _), let .discarded(card, _): card
        }
    }

    /// The read-only sheet's status line, which says why it can't be changed:
    /// "Done on 4 Nov 2026", "Done on 4 Nov 2026 · Archived" or "Discarded on
    /// 6 Nov 2026", after a symbol; the date in the user's locale, as in the Archive.
    /// `nil` for the sheets that edit.
    private var status: (symbol: String, text: String)? {
        switch mode {
        case .new, .edit: nil
        case let .done(_, date, false): ("checkmark.circle", "Done on \(Self.format(date))")
        case let .done(_, date, true): ("archivebox", "Done on \(Self.format(date)) · Archived")
        case let .discarded(_, date): ("xmark.circle", "Discarded on \(Self.format(date))")
        }
    }

    private var isReadOnly: Bool { status != nil }

    private static func format(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)
    }

    /// The width of the title and notes: the sheet's 400 less its margins.
    private static let contentWidth: CGFloat = 360

    override func loadView() {
        let headingText = switch mode {
        case .new: "New Card"
        case .edit: "Edit Card"
        case .done: "Done Card"
        case .discarded: "Discarded Card"
        }
        let heading = NSTextField(labelWithString: headingText)
        heading.font = .preferredFont(forTextStyle: .headline)

        let content = status.map(readOnlyContent) ?? editableContent()
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

        let stack = SheetStackView(views: [heading] + content.views + [buttons])
        // Esc as a key equivalent, as the edit sheet's Cancel button has it: it
        // reaches the sheet even while the selectable title or notes have focus.
        if isReadOnly { stack.onEscape = { [weak self] in self?.close() } }
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        for (view, spacing) in content.spacing { stack.setCustomSpacing(spacing, after: view) }
        stack.setCustomSpacing(16, after: content.views.last!)
        for view in content.fullWidth + [buttons] {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        }
        stack.widthAnchor.constraint(equalToConstant: Self.contentWidth + 40).isActive = true
        view = stack
    }

    private typealias Content = (views: [NSView], fullWidth: [NSView], spacing: [(NSView, CGFloat)])

    /// The title field and the notes box, each with its label.
    private func editableContent() -> Content {
        // Both fields labelled the same way (HIG audit, finding 8).
        let titleLabel = NSTextField(labelWithString: "Title")
        titleLabel.textColor = .secondaryLabelColor
        titleField.setAccessibilityTitleUIElement(titleLabel)  // VoiceOver: "Title"
        titleField.stringValue = card?.title ?? ""
        titleField.delegate = self

        let notesLabel = NSTextField(labelWithString: "Notes")
        notesLabel.textColor = .secondaryLabelColor
        notesView.setAccessibilityTitleUIElement(notesLabel)
        notesView.font = .preferredFont(forTextStyle: .body)
        notesView.string = card?.notes ?? ""
        notesView.isRichText = false
        notesView.allowsUndo = true
        notesView.onReturn = { [weak self] in self?.save(nil) }
        notesView.textContainerInset = NSSize(width: 2, height: 4)
        let notesScroll = NSScrollView()
        notesScroll.documentView = notesView
        notesScroll.hasVerticalScroller = true
        notesScroll.borderType = .noBorder
        let notesBox = RoundedBox(around: notesScroll)
        notesView.autoresizingMask = [.width]
        notesView.isVerticallyResizable = true
        notesView.textContainer?.widthTracksTextView = true
        notesBox.heightAnchor.constraint(equalToConstant: 100).isActive = true

        return ([titleLabel, titleField, notesLabel, notesBox], [titleField, notesBox],
                [(titleLabel, 4), (notesLabel, 4)])  // a label sits with its field
    }

    /// Text that can't be edited is a label, not a field (HIG): the status line
    /// that says why, the title in bold and the notes as plain wrapping text,
    /// both selectable so they can be copied.
    private func readOnlyContent(_ status: (symbol: String, text: String)) -> Content {
        let image = DecorativeImageView(image: NSImage(systemSymbolName: status.symbol, accessibilityDescription: nil) ?? NSImage())
        image.contentTintColor = .secondaryLabelColor
        let label = NSTextField(labelWithString: status.text)
        label.textColor = .secondaryLabelColor
        let statusLine = NSStackView(views: [image, label])
        statusLine.orientation = .horizontal
        statusLine.spacing = 4

        let title = NSTextField(wrappingLabelWithString: card?.title ?? "")  // selectable
        title.font = .boldSystemFont(ofSize: NSFont.preferredFont(forTextStyle: .body).pointSize)
        title.preferredMaxLayoutWidth = Self.contentWidth

        let notesText = card?.notes ?? ""
        let notes: NSView
        if notesText.isEmpty {
            let none = NSTextField(labelWithString: "No notes")
            none.textColor = .secondaryLabelColor
            notes = none
        } else {
            notes = readOnlyNotes(notesText)
        }
        return ([statusLine, title, notes], [title], [(statusLine, 16), (title, 8)])
    }

    /// Selectable body text without a border or background; as tall as the notes,
    /// up to a limit past which they scroll.
    private func readOnlyNotes(_ text: String) -> NSView {
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: Self.contentWidth, height: 0))
        textView.string = text
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .labelColor
        textView.isRichText = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        // Wrapped at the sheet's width before the height is measured below.
        textView.textContainer?.containerSize = NSSize(width: Self.contentWidth, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.setAccessibilityRole(.staticText)  // VoiceOver reads it as text, not a text area
        textView.setAccessibilityValue(text)

        var height: CGFloat = 0
        if let layout = textView.layoutManager, let container = textView.textContainer {
            layout.ensureLayout(for: container)
            height = ceil(layout.usedRect(for: container).height)
        }
        textView.frame.size.height = height
        let visibleHeight = min(max(height, 1), 240)

        // Sized before it gets the text view: growing from zero would widen the
        // text view by the same amount through its autoresizing.
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: Self.contentWidth, height: visibleHeight))
        scroll.documentView = textView
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.widthAnchor.constraint(equalToConstant: Self.contentWidth),
            scroll.heightAnchor.constraint(equalToConstant: visibleHeight),
        ])
        return scroll
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

/// The notes field. Return (and keypad Enter) saves, as in the title field;
/// with an empty title it does nothing rather than start a new line. ⇧Return,
/// ⌥Return and ⇧⌥Return start a new line. Tab and Shift-Tab move to the next and
/// previous field, as in any Mac dialog; ⌥Tab still types a tab.
private final class NotesTextView: NSTextView {
    /// What plain Return does while editing: the sheet's save.
    var onReturn: (() -> Void)?

    override func insertTab(_ sender: Any?) {
        window?.selectNextKeyView(sender)
    }

    override func insertBacktab(_ sender: Any?) {
        window?.selectPreviousKeyView(sender)
    }

    /// Handled here, before the default button sees it: a disabled Save button
    /// would let plain Return through as a new line.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let isReturn = event.keyCode == 36 || event.keyCode == 76  // Return, keypad Enter
        guard isReturn, window?.firstResponder === self, isEditable else {
            return super.performKeyEquivalent(with: event)
        }
        // An input method composing text (Japanese, Pinyin, dead keys) takes Return
        // to accept the candidate: pass it on as a normal key press.
        if hasMarkedText() {
            keyDown(with: event)
            return true
        }
        let modifiers = event.modifierFlags.intersection([.shift, .option, .control, .command])
        if modifiers.isEmpty {
            // A held Return would save again while the sheet is still closing.
            if !event.isARepeat { onReturn?() }
            return true
        }
        if modifiers.isSubset(of: [.shift, .option]) {
            insertNewline(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

/// The sheet's root view. Esc closes the read-only sheet whatever has focus: a
/// focused text view would otherwise take `cancelOperation` for itself.
private final class SheetStackView: NSStackView {
    var onEscape: (() -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection([.shift, .option, .control, .command])
        if let onEscape, event.keyCode == 53, modifiers.isEmpty {  // Esc
            onEscape()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

/// A symbol beside text that already says it all: VoiceOver skips it.
/// `setAccessibilityElement(false)` alone leaves NSImageView in the tree.
private final class DecorativeImageView: NSImageView {
    override func isAccessibilityElement() -> Bool { false }
    override func accessibilityRole() -> NSAccessibility.Role? { nil }
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
