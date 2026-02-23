#!/bin/bash
set -e

APP_NAME="JadwalSolat"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# ── Version Management ──
VERSION_FILE="VERSION"
BUILD_NUMBER_FILE="BUILD_NUMBER"

# Read version
VERSION=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo "1.0.0")

# Read and increment build number
BUILD_NUMBER=$(cat "$BUILD_NUMBER_FILE" 2>/dev/null | tr -d '[:space:]' || echo "0")
BUILD_NUMBER=$((BUILD_NUMBER + 1))
echo "$BUILD_NUMBER" > "$BUILD_NUMBER_FILE"

echo "Building v${VERSION} (build ${BUILD_NUMBER})..."
swift build -c release

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$MACOS/$APP_NAME"

cp -R Resources/. "$RESOURCES/"

# Create Info.plist with version info
cat > "$CONTENTS/Info.plist" << PLIST
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
    <string>${BUILD_NUMBER}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Jadwal Solat membutuhkan lokasi untuk menghitung waktu solat yang akurat di daerah Anda.</string>
    <key>NSLocationUsageDescription</key>
    <string>Jadwal Solat membutuhkan lokasi untuk menyesuaikan jadwal Ibadah.</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
PLIST

echo ""
echo "✅ JadwalSolat v${VERSION} (build ${BUILD_NUMBER})"
echo "   App bundle: $APP_BUNDLE"
echo ""
echo "   To run:     open $APP_BUNDLE"
echo "   To install: cp -r $APP_BUNDLE /Applications/"
