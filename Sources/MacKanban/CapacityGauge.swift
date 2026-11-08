import AppKit
import KanbanCore

/// The toolbar's "5 of 8": Open Cards against Capacity, orange when one or two
/// slots are left and red when none are. Clicking it shows what makes up Capacity.
@MainActor
final class CapacityGauge: NSButton {
    private var capacity: Capacity?

    init() {
        super.init(frame: .zero)
        // No border of its own at rest, like the New Card item beside it (HIG audit,
        // finding 3), but the toolbar's highlight under the pointer and a press state.
        bezelStyle = .toolbar
        showsBorderOnlyWhileMouseInside = true
        font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        target = self
        action = #selector(showBreakdown(_:))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func show(_ capacity: Capacity) {
        self.capacity = capacity
        let color: NSColor = switch capacity.free {
        case ...0: .systemRed
        case 1...2: .systemOrange
        default: .labelColor
        }
        attributedTitle = NSAttributedString(string: "\(capacity.openCards) of \(capacity.total)", attributes: [
            .foregroundColor: color, .font: font as Any,
        ])
        toolTip = Self.breakdown(of: capacity)
        setAccessibilityLabel("Capacity: \(capacity.openCards) of \(capacity.total) used")
    }

    @objc private func showBreakdown(_ sender: Any?) {
        guard let capacity else { return }
        let label = NSTextField(labelWithString: Self.breakdown(of: capacity))
        label.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        let content = NSView()
        content.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: content.topAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -14),
            label.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12),
        ])
        let controller = NSViewController()
        controller.view = content
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = controller
        popover.show(relativeTo: bounds, of: self, preferredEdge: .minY)
    }

    /// What makes up Capacity (ADR 0001), adding up to the total it shows,
    /// including the rounding down and the cap.
    static func breakdown(of capacity: Capacity) -> String {
        let number = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(2))
        let days = Capacity.throughputWindowDays
        let result = if capacity.unrounded > Double(Capacity.cap) {
            "= \(capacity.unrounded.formatted(number)), capped at \(Capacity.cap)"
        } else {
            "= \(capacity.unrounded.formatted(number)), rounded down to \(capacity.total)"
        }
        let free = capacity.free > 0 ? "\(capacity.free) free" : "no room for new Cards"
        return """
        Base \(Capacity.base)
        +\(capacity.throughput) Throughput: Cards finished in the last \(days) days
        −\(capacity.aging.formatted(number)) from aging Cards
        \(result)
        Capacity \(capacity.total) · \(capacity.openCards) Open Cards · \(free)
        """
    }
}
