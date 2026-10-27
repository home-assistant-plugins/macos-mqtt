#!/bin/bash
# Notarize and staple both architecture-specific MQTT Bridge disk images.
# Requires an app-specific password (https://appleid.apple.com → App-Specific Passwords).
#
# Usage:
#   APPLE_ID="you@example.com" TEAM_ID="3LMA9TXC7Z" APP_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
#       scripts/notarize.sh [version]
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${1:-1.0.0}"
: "${APPLE_ID:?Set APPLE_ID}"
: "${TEAM_ID:?Set TEAM_ID}"
: "${APP_PASSWORD:?Set APP_PASSWORD (app-specific password)}"

for SUFFIX in Apple-Silicon Intel-Macs; do
    DMG="dist/MQTT-Bridge-$VERSION-$SUFFIX.dmg"
    [ -f "$DMG" ] || { echo "Build first: scripts/build.sh $VERSION (missing $DMG)"; exit 1; }

    echo "==> submitting $DMG to Apple notary service (takes a few minutes)…"
    xcrun notarytool submit "$DMG" \
        --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_PASSWORD" --wait

    echo "==> stapling"
    xcrun stapler staple "$DMG"
    xcrun stapler validate "$DMG"
    echo "Notarized + stapled: $DMG"
done
