#!/bin/bash
# PostToolUse hook: keeps the checked-in Xcode project in step with the source folders and
# project.yml. XcodeGen only picks up added, removed or renamed files when it regenerates, and
# forgetting to is the easiest way to break the build (or Xcode Cloud, which reads the checked-in
# project). Fast when nothing changed: it compares the .swift files on disk with the project's list.
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0
command -v xcodegen >/dev/null || exit 0

# Only react to changes that can matter: .swift files, project.yml, Config/, or a shell command
# (which may have moved or deleted files).
input=$(cat)
tool=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null)
if [ "$tool" != "Bash" ]; then
    path=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
    case "$path" in
        *.swift|*project.yml|*/Config/*) ;;
        *) exit 0 ;;
    esac
fi

name=$(awk '/^name:/ {print $2; exit}' project.yml)
pbx="$name.xcodeproj/project.pbxproj"
reason=""
if [ ! -f "$pbx" ]; then
    reason="the Xcode project was missing"
elif [ project.yml -nt "$pbx" ]; then
    reason="project.yml changed"
else
    # .swift files on disk vs. those the project lists. Names are unique enough in practice.
    disk=$(find "$name" Shared "${name}Widgets" "${name}Tests" -name '*.swift' 2>/dev/null \
        | sed 's|.*/||' | sort -u)
    listed=$(grep -o '[A-Za-z0-9_+.-]*\.swift in Sources' "$pbx" | sed 's/ in Sources//' | sort -u)
    [ "$disk" = "$listed" ] || reason="Swift files were added, removed or renamed"
fi
[ -n "$reason" ] || exit 0

if out=$(xcodegen generate --quiet 2>&1); then
    msg="Regenerated $name.xcodeproj because $reason. Commit the project along with the change."
else
    msg="xcodegen generate failed after $reason: $out"
fi
python3 -c 'import json,sys; print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": sys.argv[1]}}))' "$msg"
