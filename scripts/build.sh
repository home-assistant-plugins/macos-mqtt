#!/bin/bash
# Build, bundle and code-sign Apple Silicon and Intel versions of MQTT Bridge.
# Usage: SIGN_ID="Developer ID Application: …" scripts/build.sh [version]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-1.0.0}"
SIGN_ID="${SIGN_ID:-Developer ID Application: Ba DUong (3LMA9TXC7Z)}"
DIST="dist"
STAGE="$DIST/dmg-stage"

build_variant() {
    local variant="$1"
    local triple="$2"
    local app_name="$3"
    local dmg_suffix="$4"
    local app="$DIST/$app_name.app"
    local dmg="$DIST/MQTT-Bridge-$VERSION-$dmg_suffix.dmg"

    echo "==> swift build -c release --triple $triple"
    swift build -c release --triple "$triple"
    local bin=".build/out/Products/Release/MqttBridge"

    echo "==> assembling $app"
    rm -rf "$app"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cp "$bin" "$app/Contents/MacOS/MqttBridge"
    sed "s/__VERSION__/$VERSION/g" Info.plist > "$app/Contents/Info.plist"
    if [ -f Resources/AppIcon.icns ]; then
        cp Resources/AppIcon.icns "$app/Contents/Resources/"
    fi

    echo "==> codesign ($variant: $SIGN_ID)"
    codesign --force --options runtime --timestamp \
        --entitlements entitlements.plist \
        --sign "$SIGN_ID" "$app"
    codesign --verify --strict --verbose=2 "$app"
    codesign -dvv "$app" 2>&1 | grep -E 'Authority=Developer|TeamIdentifier' || true

    echo "==> creating $dmg"
    rm -rf "$STAGE"
    mkdir -p "$STAGE"
    cp -R "$app" "$STAGE/"
    ln -s /Applications "$STAGE/Applications"
    rm -f "$dmg"
    hdiutil create -volname "MQTT Bridge ($variant)" -srcfolder "$STAGE" \
        -ov -format UDZO "$dmg" >/dev/null
    rm -rf "$STAGE"
    codesign --force --timestamp --sign "$SIGN_ID" "$dmg"
    echo "Done: $app"
    echo "      $dmg"
}

mkdir -p "$DIST"
build_variant "Apple Silicon" "arm64-apple-macosx14.0" "MQTT Bridge" "Apple-Silicon"
build_variant "Intel Macs" "x86_64-apple-macosx14.0" "MQTT Bridge (Intel Macs)" "Intel-Macs"
