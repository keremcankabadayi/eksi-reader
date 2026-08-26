#!/usr/bin/env bash
# Simulatorde calistirip sim-screenshot.png uretir (sadece macOS).
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="SukelaLite"
BUNDLE_ID="com.kerem.sukelalite"
DEVICE="${DEVICE:-iPhone 16}"
BUILD_DIR="$PWD/build"

command -v xcodebuild >/dev/null 2>&1 || { echo "hata: xcodebuild yok (macOS gerekir)" >&2; exit 1; }
command -v xcodegen  >/dev/null 2>&1 || { echo "hata: xcodegen yok (brew install xcodegen)" >&2; exit 1; }

node tools/make-icon.mjs
xcodegen generate --spec project.yml --quiet

xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -derivedDataPath "$BUILD_DIR" \
  build

APP_PATH="$BUILD_DIR/Build/Products/Debug-iphonesimulator/$APP_NAME.app"

xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" -b
xcrun simctl install "$DEVICE" "$APP_PATH"
xcrun simctl launch "$DEVICE" "$BUNDLE_ID"
sleep 3
xcrun simctl io "$DEVICE" screenshot sim-screenshot.png
echo "==> sim-screenshot.png hazir"
