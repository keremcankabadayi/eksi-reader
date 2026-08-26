#!/usr/bin/env bash
# Imzasiz IPA uretir. SideStore telefonda kendi imzasini atacagi icin
# burada hicbir sertifika/Apple ID gerekmiyor.
#
# Ortam degiskenleri (istege bagli):
#   MARKETING_VERSION=1.0.1  BUILD_NUMBER=42  ./build-ipa.sh
#   SIDELOAD_DIR=~/Library/Mobile\ Documents/com~apple~CloudDocs/Sideload
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="SukelaLite"
BUILD_DIR="$PWD/build"
DIST_DIR="$PWD/dist"
MARKETING_VERSION="${MARKETING_VERSION:-$(cat VERSION)}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "hata: xcodebuild yok. Bu betik macOS + Xcode gerektirir." >&2
  echo "      Linux/Codespaces'te derleme yapilamaz; GitHub Actions kullan." >&2
  exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "hata: xcodegen yok. Kur: brew install xcodegen" >&2
  exit 1
fi

echo "==> ikon uretiliyor"
node tools/make-icon.mjs

echo "==> xcodeproj uretiliyor"
xcodegen generate --spec project.yml --quiet

echo "==> derleniyor ($MARKETING_VERSION build $BUILD_NUMBER)"
rm -rf "$BUILD_DIR/Build/Products"
xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -sdk iphoneos \
  -destination "generic/platform=iOS" \
  -derivedDataPath "$BUILD_DIR" \
  MARKETING_VERSION="$MARKETING_VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  build

APP_PATH="$BUILD_DIR/Build/Products/Release-iphoneos/$APP_NAME.app"
[ -d "$APP_PATH" ] || { echo "hata: $APP_PATH bulunamadi" >&2; exit 1; }

echo "==> IPA paketleniyor"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/Payload"
cp -R "$APP_PATH" "$DIST_DIR/Payload/"
# Imzasiz build'de bos _CodeSignature kalabiliyor, temizle.
rm -rf "$DIST_DIR/Payload/$APP_NAME.app/_CodeSignature"
( cd "$DIST_DIR" && zip -qry "$APP_NAME.ipa" Payload )
rm -rf "$DIST_DIR/Payload"

if [ -n "${SIDELOAD_DIR:-}" ] && [ -d "$SIDELOAD_DIR" ]; then
  cp "$DIST_DIR/$APP_NAME.ipa" "$SIDELOAD_DIR/"
  echo "==> kopyalandi: $SIDELOAD_DIR/$APP_NAME.ipa"
fi

echo "==> hazir: dist/$APP_NAME.ipa"
