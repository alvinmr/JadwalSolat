#!/bin/bash
set -e

APP_NAME="JadwalSolat"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "Building release..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$MACOS/$APP_NAME"

cp -R Resources/. "$RESOURCES/"

# Create Info.plist with bundle identifier
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.jadwalsolat.app</string>
    <key>CFBundleName</key>
    <string>Jadwal Solat</string>
    <key>CFBundleDisplayName</key>
    <string>Jadwal Solat</string>
    <key>CFBundleExecutable</key>
    <string>JadwalSolat</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Jadwal Solat membutuhkan lokasi untuk menghitung waktu solat yang akurat di daerah Anda.</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
PLIST

echo "App bundle created at: $APP_BUNDLE"
echo ""
echo "To run:  open $APP_BUNDLE"
echo "To install: cp -r $APP_BUNDLE /Applications/"
