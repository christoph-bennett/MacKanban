# 01: Skeleton: an empty Board window and a status item

**What to build:** A runnable MacKanban. A SwiftPM package with the `KanbanCore` library and the `MacKanban` app target, plus bundle, install and test scripts that work like MacJot's (ad-hoc-signed app in `build/`, installed to `~/Applications/` and restarted). The app is a regular Dock app (no `LSUIElement`), bundle ID `com.onethingwell.mackanban`, macOS 14+. It opens a Board window with three empty, fixed Columns titled Backlog, Doing and Done, and puts a status item in the menu bar with **Open Board** and **Quit**. The test script runs an empty Swift Testing suite for `KanbanCore` (one placeholder test that proves the setup works).

**Blocked by:** None (can start immediately)

**Status:** ready-for-agent

- [ ] `swift build` and the test script succeed with only the Command Line Tools
- [ ] The bundle script produces `build/MacKanban.app` and the install script installs and launches it
- [ ] The app shows a Dock icon, appears in ⌘Tab and opens the Board window with three empty Columns
- [ ] The status item menu has Open Board (brings the window forward, reopening it if closed) and Quit
- [ ] Closing the Board window doesn't quit the app
- [ ] Follows light and dark appearance
