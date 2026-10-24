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
cp "$BIN_DIR/MacKanban" "$APP/Contents/MacOS/MacKanban"
# Made by scripts/make-icon.sh from the artwork (scripts/icon-artwork.swift draws it).
cp Resources/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign - "$APP"
echo "Built $APP"
