#!/bin/bash
# Builds ~/Applications/AeroSpaceFocusSink.app from main.swift.
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/Applications/AeroSpaceFocusSink.app"
mkdir -p "$APP/Contents/MacOS"
/usr/bin/swiftc -O "$DIR/main.swift" -o "$APP/Contents/MacOS/AeroSpaceFocusSink"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>com.hbak.aerospace-focus-sink</string>
  <key>CFBundleName</key><string>AeroSpaceFocusSink</string>
  <key>CFBundleExecutable</key><string>AeroSpaceFocusSink</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
/usr/bin/codesign --force --sign - "$APP"
echo "$APP"
