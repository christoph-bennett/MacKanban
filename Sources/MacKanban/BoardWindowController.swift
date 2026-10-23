import AppKit
import KanbanCore

/// The Board window: the three fixed Columns side by side.
@MainActor
final class BoardWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "MacKanban"
        window.minSize = NSSize(width: 600, height: 360)
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("Board")
        if !window.setFrameUsingName("Board") { window.center() }

        let columnViews = Column.allCases.map(ColumnView.init)
        let columns = NSStackView(views: columnViews)
        columns.orientation = .horizontal
        columns.distribution = .fillEqually
        columns.alignment = .top
        columns.spacing = 12
        columns.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        window.contentView = columns
        for view in columnViews {
            view.heightAnchor.constraint(equalTo: columns.heightAnchor, constant: -32).isActive = true
        }
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
}

/// One Column: its title above an area that will hold its Cards.
@MainActor
private final class ColumnView: NSView {
    init(column: Column) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 10

        let title = NSTextField(labelWithString: column.title)
        title.font = .preferredFont(forTextStyle: .headline)
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)
        setAccessibilityLabel(column.title)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            title.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    // A layer colour doesn't follow appearance changes on its own.
    override func updateLayer() {
        layer?.backgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.08).cgColor
    }

    override var wantsUpdateLayer: Bool { true }
}
