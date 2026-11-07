import AppKit
import KanbanCore
import KeyboardShortcuts

/// Settings, in three tabs switched from the toolbar as in MacJot (spec 0002,
/// spec 0004). General: the age labels on Cards and Launch at login. Board: the
/// WIP Limit, the only rule the user can change (ADR 0001), and the Archive Delay
/// (spec 0003). Shortcuts: the Show Board and New Card hotkeys.
/// AppKit rather than SwiftUI: a WIP Limit change has to go through the Board,
/// which records it as a Board Event.
@MainActor
final class SettingsWindowController: NSWindowController, NSToolbarDelegate {
    enum Pane: Int, CaseIterable {
        case general, board, shortcuts

        var title: String {
            switch self {
            case .general: "General"
            case .board: "Board"
            case .shortcuts: "Shortcuts"
            }
        }
    }

    static let wipLimitKey = "wipLimit"
    static let archiveDelayKey = "archiveDelay"
    /// Here rather than in a View menu, where people would look for it (decided
    /// 2026-10-24, overriding HIG audit finding 5).
    static let showsAgesKey = "showsAges"

    /// After a setting the Board computes with changed (the WIP Limit, the Archive
    /// Delay), so the Board window, and through it the Archive, show the result at once.
    var onBoardSettingChange: (() -> Void)?
    /// After the age labels were switched on or off.
    var onShowsAgesChange: ((Bool) -> Void)?

    private let board: Board
    private let defaults: UserDefaults
    private let offersLaunchAtLogin: Bool
    private let registersHotkey: Bool
    private let wipLimit = NSPopUpButton()
    private let archiveDelay = NSPopUpButton()
    private let showsAges = NSButton(checkboxWithTitle: "Show ages on Cards", target: nil, action: nil)
    private let launchAtLogin = NSButton(checkboxWithTitle: "Open MacKanban at login", target: nil, action: nil)
    private let approvalNote = NSTextField(wrappingLabelWithString: "")
    /// Shown only while Launch at login needs approval.
    private var approvalRow: NSGridRow!
    private var panes: [Pane: NSView] = [:]
    private var current: Pane?
    /// Per hotkey, the row saying another app holds its combination: shown only then.
    private var unavailableRows: [(Hotkey, NSGridRow)] = []
    private static let switcherID = NSToolbarItem.Identifier("SettingsPanes")
    private lazy var switcher: NSSegmentedControl = {
        let control = NSSegmentedControl(labels: Pane.allCases.map(\.title), trackingMode: .selectOne,
                                         target: self, action: #selector(switchPane(_:)))
        // Equal segments, like the toolbar switchers in Apple's apps (and MacJot's).
        let font = control.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let widest = Pane.allCases.map { ($0.title as NSString).size(withAttributes: [.font: font]).width }.max() ?? 0
        for index in Pane.allCases.indices { control.setWidth(ceil(widest) + 24, forSegment: index) }
        control.setAccessibilityLabel("Settings")
        return control
    }()

    /// - Parameters:
    ///   - offersLaunchAtLogin: false for a sample store, where opening at login
    ///     would still register the real app.
    ///   - registersHotkey: false for a sample store: its MacKanban leaves the hotkey
    ///     to the real one, and KeyboardShortcuts keeps it in the standard defaults,
    ///     so recording one here would change the real app's.
    init(board: Board, defaults: UserDefaults, offersLaunchAtLogin: Bool, registersHotkey: Bool) {
        self.board = board
        self.defaults = defaults
        self.offersLaunchAtLogin = offersLaunchAtLogin
        self.registersHotkey = registersHotkey
        let window = SettingsWindow(contentRect: .zero, styleMask: [.titled, .closable], backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        let toolbar = NSToolbar(identifier: "Settings")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.centeredItemIdentifiers = [Self.switcherID]
        window.toolbar = toolbar
        window.toolbarStyle = .unified
        // The switcher takes the title's place; the title (the tab's name) still
        // names the window for VoiceOver and Mission Control.
        window.titleVisibility = .hidden

        for limit in Board.wipLimits {
            wipLimit.addItem(withTitle: String(limit))
            wipLimit.lastItem?.tag = limit
        }
        wipLimit.target = self
        wipLimit.action = #selector(wipLimitChanged(_:))
        let wipNote = Self.note("The most Cards Doing can hold. Starting another Card is refused until one leaves Doing.")

        for days in Board.archiveDelays {
            archiveDelay.addItem(withTitle: days == 1 ? "1 day" : "\(days) days")
            archiveDelay.lastItem?.tag = days
        }
        archiveDelay.target = self
        archiveDelay.action = #selector(archiveDelayChanged(_:))
        let archiveNote = Self.note("How long Done Cards stay on the Board before they go to the Archive. Archiving early doesn't change Throughput.")

        showsAges.target = self
        showsAges.action = #selector(showsAgesChanged(_:))
        let agesNote = Self.note("How long each Card has been on the Board, or in Doing. The tints show Urgency either way.")

        launchAtLogin.target = self
        launchAtLogin.action = #selector(launchAtLoginChanged(_:))
        approvalNote.font = .preferredFont(forTextStyle: .callout)
        approvalNote.textColor = .secondaryLabelColor
        approvalNote.stringValue = "Turned off under Login Items in System Settings. Switch it on there."
        let openSystemSettings = NSButton(title: "Open Login Items…", target: self, action: #selector(openLoginItems(_:)))
        let approval = NSStackView(views: [approvalNote, openSystemSettings])
        approval.orientation = .vertical
        approval.alignment = .leading

        // A fixed width: with only a preferred one, the grid squeezed the notes
        // narrower than they were measured for and cut them off.
        [wipNote, archiveNote, agesNote, approvalNote].forEach(Self.fixWidth)

        let general = Self.settingsGrid([
            [NSTextField(labelWithString: "Cards:"), showsAges],
            [NSGridCell.emptyContentView, agesNote],
            [NSTextField(labelWithString: "Startup:"), launchAtLogin],
            [NSGridCell.emptyContentView, approval],
        ])
        approvalRow = general.cell(for: approval)?.row
        // The rules for how Cards flow over the Board (spec 0004).
        let boardGrid = Self.settingsGrid([
            [NSTextField(labelWithString: "WIP Limit:"), wipLimit],
            [NSGridCell.emptyContentView, wipNote],
            [NSTextField(labelWithString: "Archive Delay:"), archiveDelay],
            [NSGridCell.emptyContentView, archiveNote],
        ])

        panes[.general] = Self.paneView(around: general)
        panes[.board] = Self.paneView(around: boardGrid)
        panes[.shortcuts] = makeShortcutsPane()
        // Next time it opens on General; after it's off screen, so the switch isn't seen.
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window,
                                               queue: .main) { [weak self] _ in
            DispatchQueue.main.async { self?.select(.general, animated: false) }
        }
        select(.general, animated: false)
    }

    /// Labels right-aligned beside their controls, in MacJot's Settings spacing (HIG
    /// audit, finding 7): an explanation 4 pt below its control, 16 pt between
    /// settings, so 12 pt more under a row without a label when a labelled row follows.
    private static func settingsGrid(_ rows: [[NSView]]) -> NSGridView {
        let grid = NSGridView(views: rows)
        grid.column(at: 0).xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        grid.rowSpacing = 4
        grid.columnSpacing = 8
        for index in rows.indices.dropLast()
        where rows[index].first === NSGridCell.emptyContentView && rows[index + 1].first !== NSGridCell.emptyContentView {
            grid.row(at: index).bottomPadding = 12
        }
        return grid
    }

    /// A tab's content with Settings' margins.
    private static func paneView(around content: NSView) -> NSView {
        let pane = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        pane.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: pane.topAnchor, constant: 20),
            content.leadingAnchor.constraint(equalTo: pane.leadingAnchor, constant: 30),
            content.trailingAnchor.constraint(equalTo: pane.trailingAnchor, constant: -30),
            content.bottomAnchor.constraint(equalTo: pane.bottomAnchor, constant: -20),
        ])
        return pane
    }

    /// Per hotkey, the recorder (KeyboardShortcuts' own, its text centred by MacJot's
    /// patch) and Restore Default: Show Board (spec 0002), then New Card (MVP ticket
    /// 17). The package refuses combinations in MacKanban's menus and warns about ones
    /// macOS uses; a combination another app holds, or the other hotkey's, is refused
    /// here. A refused one isn't saved, so the previous hotkey stays. Clearing one
    /// turns it off. A sample store's MacKanban registers neither and says so.
    private func makeShortcutsPane() -> NSView {
        let rows: [[NSView]]
        var sections: [(hotkey: Hotkey, unavailableNote: NSView, explanation: NSView, last: NSView)] = []
        if registersHotkey {
            let explanations = [
                "Brings the Board to the front from any app. Pressed again while the Board is in front, it closes it, as Esc does.",
                "Brings the Board to the front with the New Card sheet on it, as ⌘N does. Pressed in another app, closing the sheet takes you back there.",
            ]
            var all: [[NSView]] = []
            for (hotkey, text) in zip(Hotkey.all, explanations) {
                let section = hotkeyRows(hotkey, explaining: text)
                all += section.rows
                sections.append((hotkey, section.unavailableNote, section.explanation, section.rows.last!.last!))
            }
            rows = all
        } else {
            let sampleNote = Self.note("Not active in a MacKanban opened on a sample store, so they don’t take the hotkeys from your real MacKanban.")
            Self.fixWidth(of: sampleNote)
            rows = Hotkey.all.map { [NSTextField(labelWithString: "\($0.title):"), Self.note("Off")] }
                + [[NSGridCell.emptyContentView, sampleNote]]
        }
        let grid = Self.settingsGrid(rows)
        func row(of view: NSView) -> NSGridRow? { grid.cell(for: view)?.row }
        if registersHotkey {
            for section in sections {
                if let note = row(of: section.unavailableNote) { unavailableRows.append((section.hotkey, note)) }
                row(of: section.explanation)?.bottomPadding = 12
                row(of: section.last)?.bottomPadding = 20  // between the hotkeys
            }
        } else {
            grid.row(at: Hotkey.all.count).topPadding = 4
        }
        return Self.paneView(around: grid)
    }

    /// The recorder, the unavailable note (hidden unless it applies), what the hotkey
    /// does, Restore Default and what that sets.
    private func hotkeyRows(_ hotkey: Hotkey, explaining text: String)
        -> (rows: [[NSView]], unavailableNote: NSView, explanation: NSView) {
        let unavailableNote = Self.note("Another app is using this combination, so it doesn’t work in MacKanban. Record a different one.")
        unavailableNote.textColor = .systemRed
        let explanation = Self.note(text)
        let restoreNote = Self.note("Sets the hotkey back to \(hotkey.defaultDisplayString).")
        for note in [unavailableNote, explanation, restoreNote] { Self.fixWidth(of: note) }

        let recorder = KeyboardShortcuts.RecorderCocoa(for: hotkey.name) { [weak self] _ in
            // Saved only after passing the check below, so it's registered now (or cleared).
            hotkey.isUnavailable = false
            self?.refresh()
            self?.fitWindowToPane()
        }
        recorder.validateShortcut = { shortcut in
            hotkey.problem(recording: shortcut).map { .disallow(reason: $0) } ?? .allow
        }
        recorder.setAccessibilityLabel("\(hotkey.title) hotkey")
        let restore = NSButton(title: "Restore Default", target: self, action: #selector(restoreDefaultHotkey(_:)))
        restore.tag = Hotkey.all.firstIndex { $0.name == hotkey.name } ?? 0
        restore.setAccessibilityLabel("Restore Default \(hotkey.title) hotkey")
        let rows: [[NSView]] = [
            [NSTextField(labelWithString: "\(hotkey.title):"), recorder],
            [NSGridCell.emptyContentView, unavailableNote],
            [NSGridCell.emptyContentView, explanation],
            [NSGridCell.emptyContentView, restore],
            [NSGridCell.emptyContentView, restoreNote],
        ]
        return (rows, unavailableNote, explanation)
    }

    private static func fixWidth(of note: NSTextField) {
        note.preferredMaxLayoutWidth = 300
        note.widthAnchor.constraint(equalToConstant: 300).isActive = true
    }

    private static func note(_ text: String) -> NSTextField {
        let note = NSTextField(wrappingLabelWithString: text)
        note.font = .preferredFont(forTextStyle: .callout)
        note.textColor = .secondaryLabelColor
        return note
    }

    // MARK: Tabs

    @objc private func switchPane(_ control: NSSegmentedControl) {
        Pane(rawValue: control.selectedSegment).map { select($0, animated: true) }
    }

    /// Shows `pane` at its natural size, keeping the window's top edge in place.
    private func select(_ pane: Pane, animated: Bool) {
        guard let window, pane != current, let view = panes[pane] else { return }
        current = pane
        switcher.selectedSegment = pane.rawValue
        window.title = pane.title
        refresh()
        // Resized first, then shown: pinned into the old size, the tab would be
        // squeezed or stretched for the length of the animation.
        let size = view.fittingSize
        var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: size))
        frame.origin = NSPoint(x: window.frame.minX, y: window.frame.maxY - frame.height)
        window.contentView = nil
        window.setFrame(frame, display: true, animate: animated && window.isVisible)
        window.contentView = view
    }

    /// The window's content is the current tab at its natural size, top edge fixed;
    /// the note rows shown decide that size.
    private func fitWindowToPane(animated: Bool = false) {
        guard let window, let view = window.contentView else { return }
        var frame = window.frameRect(forContentRect: NSRect(origin: .zero, size: view.fittingSize))
        guard frame.size != window.frame.size else { return }
        frame.origin = NSPoint(x: window.frame.minX, y: window.frame.maxY - frame.height)
        window.setFrame(frame, display: true, animate: animated && window.isVisible)
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.switcherID]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.switcherID]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.view = switcher
        item.label = "Settings"
        return item
    }

    @objc private func restoreDefaultHotkey(_ sender: NSButton) {
        let hotkey = Hotkey.all[sender.tag]
        let problem = hotkey.restoreDefault()
        refresh()
        fitWindowToPane()
        guard let problem, let window else { return }
        let alert = NSAlert()
        alert.messageText = problem
        alert.informativeText = "So the \(hotkey.title) hotkey keeps its current combination."
        alert.beginSheetModal(for: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func showWindow(_ sender: Any?) {
        refresh()
        fitWindowToPane()
        if window?.isVisible == false { window?.center() }
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(nil)  // in front of the Board once MacKanban activates, as the Archive does
        NSApp.activateAsAsked()  // also from the menu bar extra
    }

    /// Reads the settings again: Launch at login can change in System Settings.
    private func refresh() {
        wipLimit.selectItem(withTag: board.wipLimit)
        archiveDelay.selectItem(withTag: board.archiveDelay)
        showsAges.state = defaults.bool(forKey: Self.showsAgesKey) ? .on : .off
        let state = LaunchAtLogin.state
        // Shown as on while it needs approval: it's still registered, and
        // switching it off here unregisters it.
        launchAtLogin.state = state == .on || state == .needsApproval ? .on : .off
        launchAtLogin.isEnabled = offersLaunchAtLogin && state != .unavailable
        approvalRow.isHidden = state != .needsApproval
        for (hotkey, row) in unavailableRows { row.isHidden = !hotkey.isUnavailable }
    }

    @objc private func wipLimitChanged(_ sender: NSPopUpButton) {
        let limit = sender.selectedTag()
        do {
            try board.changeWIPLimit(to: limit)
            defaults.set(limit, forKey: Self.wipLimitKey)
            onBoardSettingChange?()
        } catch {
            refresh()
            NSAlert(error: error).beginSheetModal(for: window!)
        }
    }

    @objc private func archiveDelayChanged(_ sender: NSPopUpButton) {
        do {
            try board.changeArchiveDelay(to: sender.selectedTag())
            defaults.set(board.archiveDelay, forKey: Self.archiveDelayKey)
            onBoardSettingChange?()
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

/// Esc closes Settings like ⌘W, as it closes the Archive, and as in MacJot (ticket
/// 18). Unlike the Board's Esc it doesn't hide MacKanban. On the window: an override
/// on the controller didn't receive Esc when tried (2026-11-07). A recorder that is
/// recording swallows Esc to end the recording (KeyboardShortcuts' event monitor),
/// and an open dropdown takes Esc to close itself, so neither gets this far.
private final class SettingsWindow: NSWindow {
    override func cancelOperation(_ sender: Any?) {
        performClose(sender)
    }
}
