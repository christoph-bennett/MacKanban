import AppKit
import KanbanCore

/// Settings: the WIP Limit, the only rule the user can change (ADR 0001), the
/// age labels on Cards, and Launch at login. AppKit rather than SwiftUI: a WIP Limit change has to go
/// through the Board, which records it as a Board Event.
@MainActor
final class SettingsWindowController: NSWindowController {
    static let wipLimitKey = "wipLimit"
    static let showsAgesKey = "showsAges"

    /// After the WIP Limit changed, so the Board window can update Doing's header.
    var onWIPLimitChange: (() -> Void)?
    /// After the age labels were switched on or off.
    var onShowsAgesChange: ((Bool) -> Void)?

    private let board: Board
    private let defaults: UserDefaults
    private let offersLaunchAtLogin: Bool
    private let wipLimit = NSPopUpButton()
    private let showsAges = NSButton(checkboxWithTitle: "Show ages on Cards", target: nil, action: nil)
    private let launchAtLogin = NSButton(checkboxWithTitle: "Open MacKanban at login", target: nil, action: nil)
    private let approvalNote = NSTextField(wrappingLabelWithString: "")
    private var grid: NSGridView!
    private static let approvalRow = 5

    /// - Parameter offersLaunchAtLogin: false for a sample store, where opening at
    ///   login would still register the real app.
    init(board: Board, defaults: UserDefaults, offersLaunchAtLogin: Bool) {
        self.board = board
        self.defaults = defaults
        self.offersLaunchAtLogin = offersLaunchAtLogin
        let window = NSWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: true)
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        super.init(window: window)

        wipLimit.addItems(withTitles: Board.wipLimits.map(String.init))
        wipLimit.target = self
        wipLimit.action = #selector(wipLimitChanged(_:))
        let wipNote = NSTextField(wrappingLabelWithString: "The most Cards Doing can hold. Starting another Card is refused until one leaves Doing.")
        wipNote.font = .preferredFont(forTextStyle: .callout)
        wipNote.textColor = .secondaryLabelColor

        showsAges.target = self
        showsAges.action = #selector(showsAgesChanged(_:))
        let agesNote = NSTextField(wrappingLabelWithString: "How long each Card has been on the Board, or in Doing. The tints show Urgency either way.")
        agesNote.font = .preferredFont(forTextStyle: .callout)
        agesNote.textColor = .secondaryLabelColor

        launchAtLogin.target = self
        launchAtLogin.action = #selector(launchAtLoginChanged(_:))
        approvalNote.font = .preferredFont(forTextStyle: .callout)
        approvalNote.textColor = .secondaryLabelColor
        approvalNote.stringValue = "Turned off under Login Items in System Settings. Switch it on there."
        let openSystemSettings = NSButton(title: "Open Login Items…", target: self, action: #selector(openLoginItems(_:)))
        let approval = NSStackView(views: [approvalNote, openSystemSettings])
        approval.orientation = .vertical
        approval.alignment = .leading

        grid = NSGridView(views: [
            [NSTextField(labelWithString: "WIP Limit:"), wipLimit],
            [NSGridCell.emptyContentView, wipNote],
            [NSTextField(labelWithString: "Cards:"), showsAges],
            [NSGridCell.emptyContentView, agesNote],
            [NSTextField(labelWithString: "Startup:"), launchAtLogin],
            [NSGridCell.emptyContentView, approval],
        ])
        grid.column(at: 0).xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 8
        grid.columnSpacing = 8
        grid.row(at: 1).bottomPadding = 12
        grid.row(at: 3).bottomPadding = 12
        grid.translatesAutoresizingMaskIntoConstraints = false
        // A fixed width: with only a preferred one, the grid squeezed the notes
        // narrower than they were measured for and cut them off.
        for note in [wipNote, agesNote, approvalNote] {
            note.preferredMaxLayoutWidth = 300
            note.widthAnchor.constraint(equalToConstant: 300).isActive = true
        }

        let content = NSView()
        content.addSubview(grid)
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 20),
            grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            grid.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -20),
        ])
        window.contentView = content
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func showWindow(_ sender: Any?) {
        refresh()
        if window?.isVisible == false { window?.center() }
        super.showWindow(sender)
        NSApp.activate()
    }

    /// Reads the settings again: Launch at login can change in System Settings.
    private func refresh() {
        wipLimit.selectItem(withTitle: String(board.wipLimit))
        showsAges.state = defaults.bool(forKey: Self.showsAgesKey) ? .on : .off
        let state = LaunchAtLogin.state
        // Shown as on while it needs approval: it's still registered, and
        // switching it off here unregisters it.
        launchAtLogin.state = state == .on || state == .needsApproval ? .on : .off
        launchAtLogin.isEnabled = offersLaunchAtLogin && state != .unavailable
        grid.row(at: Self.approvalRow).isHidden = state != .needsApproval
    }

    @objc private func wipLimitChanged(_ sender: NSPopUpButton) {
        guard let limit = sender.titleOfSelectedItem.flatMap(Int.init) else { return }
        do {
            try board.changeWIPLimit(to: limit)
            defaults.set(limit, forKey: Self.wipLimitKey)
            onWIPLimitChange?()
        } catch {
            refresh()
            NSAlert(error: error).beginSheetModal(for: window!)
        }
    }

    @objc private func showsAgesChanged(_ sender: NSButton) {
        defaults.set(sender.state == .on, forKey: Self.showsAgesKey)
        onShowsAgesChange?(sender.state == .on)
    }

    @objc private func launchAtLoginChanged(_ sender: NSButton) {
        let on = sender.state == .on
        let succeeded = LaunchAtLogin.set(on)
        refresh()  // shows what the system actually did
        guard !succeeded, let window else { return }
        let alert = NSAlert()
        alert.messageText = on ? "MacKanban couldn't add itself to your login items." : "MacKanban couldn't remove itself from your login items."
        alert.informativeText = "You can change it under General > Login Items in System Settings."
        alert.beginSheetModal(for: window)
    }

    @objc private func openLoginItems(_ sender: Any?) {
        LaunchAtLogin.openSystemSettings()
    }
}
