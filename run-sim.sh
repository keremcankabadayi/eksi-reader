#!/usr/bin/env bash
# Simulatorde calistirip ekran goruntusu uretir (sadece macOS).
#
# DEVICE ortam degiskeniyle cihaz secilebilir; verilmezse kurulu ilk
# iPhone simulatoru kullanilir (CI'da hangi Xcode'un geldigi degisiyor).
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="SukelaLite"
BUNDLE_ID="com.kerem.sukelalite"
BUILD_DIR="$PWD/build"
OUT_DIR="${OUT_DIR:-$PWD/screenshots}"

command -v xcodebuild >/dev/null 2>&1 || { echo "hata: xcodebuild yok (macOS gerekir)" >&2; exit 1; }
command -v xcodegen  >/dev/null 2>&1 || { echo "hata: xcodegen yok (brew install xcodegen)" >&2; exit 1; }

if [ -z "${DEVICE:-}" ]; then
  DEVICE="$(xcrun simctl list devices available \
    | grep -oE '^ +iPhone [^(]+' | head -n 1 | sed 's/^ *//;s/ *$//')"
fi
[ -n "$DEVICE" ] || { echo "hata: kullanilabilir iPhone simulatoru bulunamadi" >&2; exit 1; }
echo "==> cihaz: $DEVICE"

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

mkdir -p "$OUT_DIR"
sleep 4
xcrun simctl io "$DEVICE" screenshot "$OUT_DIR/01-gundem.png"

# Sekmeler arasi gezinmek icin UI otomasyonu gerekiyor; simdilik acilis
# ekranini aliyoruz. Koyu tema ikinci bir kare olarak cekiliyor.
xcrun simctl ui "$DEVICE" appearance dark 2>/dev/null || true
sleep 2
xcrun simctl io "$DEVICE" screenshot "$OUT_DIR/02-gundem-koyu.png"
xcrun simctl ui "$DEVICE" appearance light 2>/dev/null || true

echo "==> hazir: $OUT_DIR"
ls -la "$OUT_DIR"
