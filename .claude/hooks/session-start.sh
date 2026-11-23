#!/bin/bash
# SessionStart hook: tells Claude up front whether this machine can build the app, and brings the
# Xcode project up to date if the last session (or a git pull) left it stale.
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0

if [ "$(uname)" != "Darwin" ] || ! command -v xcodebuild >/dev/null; then
    echo "This machine has no Xcode (not macOS), so the app can't be built, tested or run here." \
         "Check SwiftUI and framework API signatures carefully, keep edits small, and tell the user" \
         "the change is unbuilt. scripts/check-consistency.py still works."
    exit 0
fi

notes=()
command -v xcodegen >/dev/null || notes+=("XcodeGen is missing: ask the user to run 'brew install xcodegen'.")
if command -v xcodegen >/dev/null; then
    name=$(awk '/^name:/ {print $2; exit}' project.yml)
    if [ ! -f "$name.xcodeproj/project.pbxproj" ] || [ project.yml -nt "$name.xcodeproj/project.pbxproj" ]; then
        xcodegen generate --quiet >/dev/null 2>&1 && notes+=("Regenerated $name.xcodeproj (it was stale).")
    fi
fi
booted=$(xcrun simctl list devices booted 2>/dev/null | grep -Eo '^ +[^(]+\(' | sed 's/^ *//; s/ *($//' | paste -sd, -)
[ -n "$booted" ] && notes+=("Booted simulators: $booted.")
[ ${#notes[@]} -gt 0 ] && printf '%s\n' "${notes[@]}"
exit 0
