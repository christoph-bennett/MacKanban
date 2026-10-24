import AppKit
import KanbanCore

/// The menu bar extra: an icon showing the Board's state at a glance, and a menu
/// with the Capacity line, the Doing Cards to finish and the everyday actions.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    var onNewCard: (() -> Void)?
    var onOpenBoard: (() -> Void)?
    var onSettings: (() -> Void)?
    /// Moves the chosen Doing Card to Done.
    var onFinish: ((UUID) -> Void)?

    private let board: Board
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var refreshTimer: Timer?

    init(board: Board) {
        self.board = board
        super.init()
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        refresh()
        // Its own timer: the Board window skips its minute refresh while hidden,
        // and the icon matters most then.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
    }

    /// After every change, and once a minute as Cards age.
    func refresh() {
        guard let state = try? board.state() else {
            // Never a stale state, and never no icon at all: the plain icon, with
            // the menu saying the Board can't be read.
            let image = NSImage(systemSymbolName: "rectangle.split.3x1", accessibilityDescription: "MacKanban")
            image?.isTemplate = true
            item.button?.image = image
            item.button?.toolTip = "MacKanban can't read the Board right now."
            return
        }
        show(state)
    }

    /// Tinted by the highest Urgency of any Open Card: neutral while none is aging,
    /// amber while one is, red once one is fully red (when Triage asks about it).
    /// Filled once there's no room for a new Card.
    func show(_ state: BoardState) {
        let urgency = Self.openCards(in: state).map(\.urgency).max() ?? 0
        let isFull = state.capacity.free <= 0
        let tint: NSColor? = switch urgency {
        case 1...: .systemRed
        case 0: nil
        default: .systemOrange
        }
        var image = NSImage(systemSymbolName: isFull ? "rectangle.split.3x1.fill" : "rectangle.split.3x1",
                            accessibilityDescription: "MacKanban")
        if let tint {
            // The menu bar ignores a tint on template images, so colour the symbol itself.
            image = image?.withSymbolConfiguration(NSImage.SymbolConfiguration(paletteColors: [tint]))
            image?.isTemplate = false
        } else {
            image?.isTemplate = true  // the menu bar's own colour, light or dark
        }
        item.button?.image = image
        let capacity = state.capacity
        item.button?.toolTip = "MacKanban: \(capacity.openCards) of \(capacity.total) used"
        item.button?.setAccessibilityLabel(
            "MacKanban, \(capacity.openCards) of \(capacity.total) used" + (isFull ? ", no room for new Cards" : ""))
    }

    // MARK: NSMenuDelegate

    /// Built fresh each time it opens, so it never shows a Card that's gone.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        guard let state = try? board.state() else {
            menu.addItem(disabled("The Board can't be read right now."))
            addActions(to: menu)
            return
        }
        show(state)

        menu.addItem(disabled(Self.capacityLine(state.capacity)))
        menu.addItem(.separator())
        menu.addItem(.sectionHeader(title: "Doing: choose a Card to move it to Done"))
        let doing = state.columns[.doing] ?? []
        if doing.isEmpty {
            menu.addItem(disabled("Nothing in Doing"))
        }
        for card in doing {
            let cardItem = NSMenuItem(title: Self.shortened(card.title), action: #selector(finish(_:)), keyEquivalent: "")
            cardItem.target = self
            cardItem.representedObject = card.id
            cardItem.toolTip = card.ageLabel(in: .doing).map { "\($0). Choose to move it to Done." }
            menu.addItem(cardItem)
        }
        addActions(to: menu)
    }

    private func addActions(to menu: NSMenu) {
        menu.addItem(.separator())
        menu.addItem(withTitle: "New Card…", action: #selector(newCard(_:)), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Open Board", action: #selector(openBoard(_:)), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Settings…", action: #selector(settings(_:)), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit MacKanban", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
    }

    @objc private func finish(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        onFinish?(id)
    }

    @objc private func newCard(_ sender: Any?) { onNewCard?() }
    @objc private func openBoard(_ sender: Any?) { onOpenBoard?() }
    @objc private func settings(_ sender: Any?) { onSettings?() }

    // MARK: Text

    /// "5 of 8 used, −2.40 from aging": two decimals, like the gauge's breakdown.
    static func capacityLine(_ capacity: Capacity) -> String {
        let aging = capacity.aging.formatted(.number.precision(.fractionLength(2)))
        return "\(capacity.openCards) of \(capacity.total) used, −\(aging) from aging"
    }

    private static func shortened(_ title: String) -> String {
        title.count <= 50 ? title : title.prefix(49) + "…"
    }

    private static func openCards(in state: BoardState) -> [Card] {
        (state.columns[.backlog] ?? []) + (state.columns[.doing] ?? [])
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
