import AppKit

// The first hover text shows after 0.3 s instead of the system's slower default
// (asked for 2026-11-07, for the Archive's Counts bars); later ones are quick anyway.
UserDefaults.standard.register(defaults: ["NSInitialToolTipDelay": 300])

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// The bundle starts without a Dock icon (LSUIElement); the setting decides, before
// any window shows (spec 0004).
AppDelegate.applyDockSetting()
app.run()
