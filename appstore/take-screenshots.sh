#!/bin/bash
# Takes the App Store screenshots in the simulator: builds a Debug copy of Sprout, launches it in
# screenshot mode (Pro unlocked with -demoPro, settings passed as launch arguments) and saves each
# screen at full resolution to appstore/screenshots/raw/<width>x<height>. frame-screenshots.swift
# then adds the captions.
#
#     appstore/take-screenshots.sh                       # the default sizes below
#     appstore/take-screenshots.sh "iPhone 17 Pro"       # other simulator device types
#
# Edit the SHOTS section to stage each screen. Anything the app saves in UserDefaults can be set with
# a launch argument (-appearance dark), and -demoTab picks the tab. Give the app more -demo flags
# (read in #if DEBUG) to fill it with sample data.
#
# Each device type runs on its own simulator, "Sprout Screenshots (<type>)", made the first time,
# so your own simulators keep their data. simctl can't unfold the iPhone Duo, so for its inner display
# the script asks you to unfold it in Xcode and press Return.
#
# Widgets and the paywall (iap-review-paywall.png, for the in-app purchase's review screenshot) can't
# be scripted: save them by hand with ⌘S into each size's raw folder.
set -euo pipefail

if [ $# -eq 0 ]; then
    set -- "iPhone 18 Pro" "iPhone Duo" "iPad Pro 13-inch (M5)"
fi
BUNDLE_ID=com.brendanchamberlain.sprout
ROOT=$(cd "$(dirname "$0")/.." && pwd)
BUILD=$(mktemp -d)
trap 'rm -rf "$BUILD"' EXIT

echo "Building…"
xcodebuild -project "$ROOT/Sprout.xcodeproj" -scheme Sprout -configuration Debug \
    -destination "generic/platform=iOS Simulator" -derivedDataPath "$BUILD" \
    CODE_SIGNING_ALLOWED=NO build -quiet
APP="$BUILD/Build/Products/Debug-iphonesimulator/Sprout.app"

# simulator TYPE: prints the UDID of the screenshot simulator for device type TYPE, making it if needed.
simulator() {
    local name="Sprout Screenshots ($1)"
    local udid
    udid=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
for runtime in json.load(sys.stdin)["devices"].values():
    for device in runtime:
        if device["name"] == sys.argv[1]:
            print(device["udid"]); sys.exit()' "$name")
    if [ -z "$udid" ]; then
        udid=$(xcrun simctl create "$name" "$1" 2>/dev/null)
    fi
    echo "$udid"
}

# is_on UDID DISPLAY: whether the display shows anything (a display that's off screenshots as black).
is_on() {
    local check
    check=$(mktemp -d)
    xcrun simctl io "$1" screenshot --type=png --display="$2" "$check/screen.png" >/dev/null 2>&1
    sips -s format bmp -z 8 8 "$check/screen.png" --out "$check/screen.bmp" >/dev/null
    python3 -c '
import sys
data = open(sys.argv[1], "rb").read()
start, step = int.from_bytes(data[10:14], "little"), data[28] // 8
pixels = data[start:]
sys.exit(0 if any(max(pixels[i:i + 3]) > 16 for i in range(0, len(pixels) - 2, step)) else 1)' "$check/screen.bmp"
    local on=$?
    rm -rf "$check"
    return $on
}

for TYPE in "$@"; do
    UDID=$(simulator "$TYPE")
    echo "$TYPE:"
    xcrun simctl bootstatus "$UDID" -b >/dev/null
    xcrun simctl ui "$UDID" appearance light
    xcrun simctl status_bar "$UDID" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
    xcrun simctl uninstall "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    xcrun simctl install "$UDID" "$APP"

    # The Duo has a cover display ("primary") and an inner one ("primary-1", on only while unfolded).
    DISPLAYS=primary
    if [ "$TYPE" = "iPhone Duo" ]; then
        DISPLAYS="primary primary-1"
    fi

    for DISPLAY in $DISPLAYS; do
        if [ "$DISPLAY" = primary ] && [ "$TYPE" = "iPhone Duo" ] && ! is_on "$UDID" "$DISPLAY"; then
            echo "  skipped the cover display: it's off while the simulator is unfolded"
            continue
        fi
        if [ "$DISPLAY" = primary-1 ] && ! is_on "$UDID" "$DISPLAY"; then
            if [ ! -t 0 ]; then
                echo "  skipped the inner display: unfold the simulator in Xcode and run this again"
                continue
            fi
            read -r -p "  Unfold \"Sprout Screenshots ($TYPE)\" in Xcode, then press Return… "
            if ! is_on "$UDID" "$DISPLAY"; then
                echo "  skipped the inner display: it's still off"
                continue
            fi
        fi

        SHOTS=$(mktemp -d)

        # shot NAME ARGS…: launches the app in screenshot mode plus ARGS and saves the screen as NAME.png.
        shot() {
            local name=$1; shift
            xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
            xcrun simctl launch "$UDID" "$BUNDLE_ID" -demoPro YES "$@" >/dev/null
            sleep 4
            xcrun simctl io "$UDID" screenshot --type=png --display="$DISPLAY" "$SHOTS/$name.png" >/dev/null 2>&1
            # Now and then the app hasn't drawn yet; a blank screen compresses to far less than a real one.
            local tries=0
            while [ "$(stat -f %z "$SHOTS/$name.png")" -lt 150000 ] && [ $tries -lt 3 ]; do
                tries=$((tries + 1))
                sleep 3
                xcrun simctl io "$UDID" screenshot --type=png --display="$DISPLAY" "$SHOTS/$name.png" >/dev/null 2>&1
            done
        }

        # The first launch after installing is slow, so it's a throwaway.
        shot warm-up -demoData YES -demoTab today
        rm "$SHOTS/warm-up.png"

        # --- SHOTS: one line per screenshot, named N-name to match frame-screenshots.swift.
        shot 1-today -demoData YES -demoTab today -appearance light
        shot 2-plant -demoData YES -demoTab plants -demoPlant Monstera -appearance light
        shot 3-plants-dark -demoData YES -demoTab plants -appearance dark
        # --- end of SHOTS

        xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
        FIRST=$(ls "$SHOTS"/*.png | head -n1)
        SIZE=$(sips -g pixelWidth -g pixelHeight "$FIRST" | awk '/pixelWidth/ {w=$2} /pixelHeight/ {h=$2} END {print w "x" h}')
        OUT="$ROOT/appstore/screenshots/raw/$SIZE"
        mkdir -p "$OUT"
        mv "$SHOTS"/*.png "$OUT"/
        rmdir "$SHOTS"
        echo "  saved to screenshots/raw/$SIZE"
    done
done
