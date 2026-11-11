#!/bin/sh
# Builds MacKanban.app into build/ from the SwiftPM executable, without Xcode.
# Ad-hoc signed: fine for local use; notarised distribution needs a Developer ID.
set -e
cd "$(dirname "$0")/.."
CONFIG="${1:-release}"
swift build -c "$CONFIG" --product MacKanban
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"

APP=build/MacKanban.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp Resources/Info.plist "$APP/Contents/Info.plist"
# The build number counts the commits, so About shows how far the app has come.
# Outside a git checkout, Info.plist's own number stays.
if BUILD="$(git rev-list --count HEAD 2>/dev/null)"; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD" "$APP/Contents/Info.plist"
fi
cp "$BIN_DIR/MacKanban" "$APP/Contents/MacOS/MacKanban"
# Made by scripts/make-icon.sh from the artwork (scripts/icon-artwork.swift draws it).
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
# The About panel shows it under the copyright: the link to the author's GitHub profile.
cp Resources/Credits.rtf "$APP/Contents/Resources/"
# KeyboardShortcuts' texts (ADR 0006); without them its recorder crashes.
cp -R "$BIN_DIR/KeyboardShortcuts_KeyboardShortcuts.bundle" "$APP/Contents/Resources/"
codesign --force --sign - "$APP"
echo "Built $APP"
