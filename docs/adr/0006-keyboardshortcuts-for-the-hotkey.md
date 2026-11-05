# KeyboardShortcuts for the show-Board hotkey, vendored as in MacJot

The global hotkey that shows the Board (spec 0002) is recorded, stored and registered with [sindresorhus/KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) (MIT), MacKanban's first third-party dependency. Spec 0001 said "no third-party dependencies"; this ADR is the exception. Christoph decided on 2026-11-05 to use it as in MacJot (its ADR 0005), for the same reasons: recording a global hotkey well takes a native recorder field, keys labelled for the current keyboard layout, hotkeys paused while recording, warnings for combinations macOS or the app's own menus use, and fixes for AppKit quirks that change with each macOS release. The package does all of that and is maintained.

It's vendored, not fetched: version 3.x uses SwiftUI macros whose plugins ship only with Xcode, and MacKanban builds with the Command Line Tools. We take MacJot's vendored copy of 3.1.0 as it is, with its four marked patches (three to build without macros; one that drops the recorder's `layout()` override, so its text is centred). The package's README in the vendor folder lists them and how to update.

## Considered Options

- **Our own recorder and Carbon hotkey registration**: rejected. The same features, but the per-macOS quirks would be ours to find, and MacJot already went through that and chose the package.
- **Fetching the package with SwiftPM**: rejected. 3.x doesn't build without Xcode; 2.x builds but lacks the recorder's custom validation.
- **A fixed hotkey with no recorder**: rejected. Christoph wants to change it in Settings, and a fixed combination can collide with another app.

## Consequences

- `scripts/bundle.sh` must copy the package's resource bundle into the app, or the recorder crashes when it shows its texts.
- Updating the package is a manual copy and re-patch, ideally done once for both apps.
- Like any approach, it can't detect a combination another app has registered without holding it exclusively; only those it can try and fail to register, and the ones macOS uses.
