import AppKit

/// The New Card sheet: a title (required) and optional notes. AppKit rather than
/// SwiftUI: SwiftUI's `@State` is a macro whose plugin ships only with Xcode.
@MainActor
final class NewCardViewController: NSViewController, NSTextFieldDelegate {
    var onCreate: ((_ title: String, _ notes: String) -> Void)?

    private let titleField = NSTextField()
    private let notesView = NSTextView()
    private let addButton = NSButton(title: "Add Card", target: nil, action: nil)

    override func loadView() {
        let heading = NSTextField(labelWithString: "New Card")
        heading.font = .preferredFont(forTextStyle: .headline)

        titleField.placeholderString = "Title"
        titleField.delegate = self

        let notesLabel = NSTextField(labelWithString: "Notes")
        notesLabel.textColor = .secondaryLabelColor
        notesView.font = .preferredFont(forTextStyle: .body)
        notesView.isRichText = false
        notesView.allowsUndo = true
        notesView.textContainerInset = NSSize(width: 2, height: 4)
        let notesScroll = NSScrollView()
        notesScroll.documentView = notesView
        notesScroll.hasVerticalScroller = true
        notesScroll.borderType = .bezelBorder
        notesView.autoresizingMask = [.width]
        notesView.isVerticallyResizable = true
        notesView.textContainer?.widthTracksTextView = true

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel(_:)))
        cancel.keyEquivalent = "\u{1b}"
        addButton.target = self
        addButton.action = #selector(add(_:))
        addButton.keyEquivalent = "\r"
        addButton.isEnabled = false
        let buttons = NSStackView(views: [NSView(), cancel, addButton])
        buttons.orientation = .horizontal

        let stack = NSStackView(views: [heading, titleField, notesLabel, notesScroll, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 10
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.setCustomSpacing(4, after: notesLabel)
        stack.setCustomSpacing(16, after: notesScroll)
        for view in [titleField, notesScroll, buttons] {
            view.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -40).isActive = true
        }
        NSLayoutConstraint.activate([
            stack.widthAnchor.constraint(equalToConstant: 400),
            notesScroll.heightAnchor.constraint(equalToConstant: 100),
        ])
        view = stack
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(titleField)
    }

    func controlTextDidChange(_ notification: Notification) {
        addButton.isEnabled = !titleField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @objc private func add(_ sender: Any?) {
        guard addButton.isEnabled else { return }
        onCreate?(titleField.stringValue, notesView.string)
    }

    @objc private func cancel(_ sender: Any?) {
        dismiss(nil)
    }
}
