#!/bin/bash
set -euo pipefail
APP_NAME="ClipboardManager"
APP_DIR="$APP_NAME.app"
rm -rf "$APP_DIR" "$APP_NAME-macOS.zip"
swift build -c release
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp ".build/release/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Clipboard Manager</string>
<key>CFBundleDisplayName</key><string>Clipboard Manager</string>
<key>CFBundleIdentifier</key><string>com.example.ClipboardManager</string>
<key>CFBundleExecutable</key><string>ClipboardManager</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>0.8.0</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
</dict></plist>
PLIST
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$APP_NAME-macOS.zip"
echo "Created $APP_NAME-macOS.zip"
