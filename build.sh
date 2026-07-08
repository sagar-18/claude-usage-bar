#!/bin/bash
# Builds ClaudeUsageBar.app from source (no download → no Gatekeeper quarantine).
# Usage: ./build.sh [output-dir]
set -euo pipefail

OUT="${1:-.}"
APP="$OUT/ClaudeUsageBar.app"
VERSION="1.2.0"

DIR="$(dirname "$0")"

echo "==> Compiling…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O "$DIR/Sources/ClaudeUsageBar.swift" -o "$APP/Contents/MacOS/ClaudeUsageBar"

echo "==> Adding icon…"
cp "$DIR/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

echo "==> Writing Info.plist…"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Claude Usage Bar</string>
    <key>CFBundleDisplayName</key><string>Claude Usage Bar</string>
    <key>CFBundleIdentifier</key><string>com.sagar18.claude-usage-bar</string>
    <key>CFBundleExecutable</key><string>ClaudeUsageBar</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleVersion</key><string>${VERSION}</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHumanReadableCopyright</key><string>MIT License. Unofficial — not affiliated with Anthropic.</string>
</dict>
</plist>
PLIST

echo "==> Ad-hoc code-signing (needed for Launch-at-Login / SMAppService)…"
codesign --force --deep --sign - "$APP" || echo "⚠️  codesign failed — the app still runs; Launch-at-Login may not work"

echo "✅ Built $APP"
