import AppKit

/// The menu bar shown while MacKanban is active. It also routes ⌘W, ⌘Q, ⌘Z and the
/// text editing shortcuts to the window and its fields.
@MainActor
enum MainMenu {
    static func make(appDelegate: AppDelegate) -> NSMenu {
        let main = NSMenu()

        let app = NSMenu()
        app.addItem(withTitle: "Hide MacKanban", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(.separator())
        app.addItem(withTitle: "Quit MacKanban", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        main.addItem(submenu: app, title: "MacKanban")

        let file = NSMenu(title: "File")
        file.addItem(withTitle: "New Card", action: #selector(AppDelegate.newCard), keyEquivalent: "n")
            .target = appDelegate
        file.addItem(.separator())
        file.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        main.addItem(submenu: file, title: "File")

        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        main.addItem(submenu: edit, title: "Edit")

        let card = NSMenu(title: "Card")
        // ⌘→ and ⌘←: the selected Card moves the way the Columns read.
        card.addItem(withTitle: "Move to Next Column", action: #selector(BoardViewController.moveToNextColumn(_:)),
                     keyEquivalent: String(UnicodeScalar(NSRightArrowFunctionKey)!))
        card.addItem(withTitle: "Move to Previous Column", action: #selector(BoardViewController.moveToPreviousColumn(_:)),
                     keyEquivalent: String(UnicodeScalar(NSLeftArrowFunctionKey)!))
        main.addItem(submenu: card, title: "Card")

        let window = NSMenu(title: "Window")
        window.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        window.addItem(.separator())
        window.addItem(withTitle: "Board", action: #selector(AppDelegate.showBoard), keyEquivalent: "0")
            .target = appDelegate
        main.addItem(submenu: window, title: "Window")
        NSApp.windowsMenu = window

        return main
    }
}

private extension NSMenu {
    func addItem(submenu: NSMenu, title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        addItem(item)
    }
}
