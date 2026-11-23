#!/bin/bash
# Builds a Debug copy of the app for the simulator, installs it and launches it.
#
#     scripts/run-app.sh                                 # the booted simulator, or iPhone 18 Pro
#     scripts/run-app.sh "iPhone Duo"                    # a device type or simulator name/UDID
#     scripts/run-app.sh "iPad Pro 13-inch (M5)" -- -demoPro YES -demoTab settings -appearance dark
#
# Anything after -- goes to the app as launch arguments: -demoPro YES unlocks Pro, -demoTab picks the
# tab, and any UserDefaults key can be set (-appearance dark). Prints the simulator's UDID last.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
NAME=$(awk '/^name:/ {print $2; exit}' "$ROOT/project.yml")
BUNDLE_ID=$(awk '/APP_BUNDLE_IDENTIFIER:/ {print $2; exit}' "$ROOT/project.yml")

DEVICE=""
if [ $# -gt 0 ] && [ "$1" != "--" ]; then DEVICE=$1; shift; fi
[ "${1:-}" = "--" ] && shift
ARGS=("$@")

if [ -z "$DEVICE" ]; then
    UDID=$(xcrun simctl list devices booted -j | python3 -c '
import json, sys
for devices in json.load(sys.stdin)["devices"].values():
    for d in devices:
        print(d["udid"]); sys.exit()')
    DEVICE=${UDID:-"iPhone 18 Pro"}
fi

# A UDID or an existing simulator's name is used as is; a device type gets a simulator of its own.
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
want = sys.argv[1]
for devices in json.load(sys.stdin)["devices"].values():
    for d in devices:
        if want in (d["udid"], d["name"]):
            print(d["udid"]); sys.exit()' "$DEVICE")
if [ -z "$UDID" ]; then
    UDID=$(xcrun simctl create "$DEVICE ($NAME)" "$DEVICE")
fi

xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$UDID" 2>/dev/null || true

BUILD="$ROOT/build/run"
echo "Building $NAME…" >&2
xcodebuild -project "$ROOT/$NAME.xcodeproj" -scheme "$NAME" -configuration Debug \
    -destination "id=$UDID" -derivedDataPath "$BUILD" CODE_SIGNING_ALLOWED=NO build -quiet >&2
xcrun simctl bootstatus "$UDID" >/dev/null
xcrun simctl install "$UDID" "$BUILD/Build/Products/Debug-iphonesimulator/$NAME.app"
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$UDID" "$BUNDLE_ID" ${ARGS[@]+"${ARGS[@]}"} >/dev/null
echo "Launched $BUNDLE_ID on $DEVICE" >&2
echo "$UDID"
