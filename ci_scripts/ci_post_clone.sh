#!/bin/sh
# Xcode Cloud runs this right after cloning. The checked-in Xcode project is generated from
# project.yml, so regenerate it in case it's out of date.
set -e

brew install xcodegen
cd "$CI_PRIMARY_REPOSITORY_PATH"

# A build started by a release tag (see .github/workflows/release.yml) takes its version from the
# tag, so project.yml doesn't need a bump commit per release.
if [ -n "$CI_TAG" ]; then
    if ! echo "$CI_TAG" | grep -Eq '^[0-9]+\.[0-9]+(\.[0-9]+)?$'; then
        echo "error: tag '$CI_TAG' isn't a version (MAJOR.MINOR[.PATCH])" >&2
        exit 1
    fi
    sed -i '' -E "s/(MARKETING_VERSION: )\"[^\"]*\"/\1\"$CI_TAG\"/" project.yml
    # The app and the widget extension share the one project-level MARKETING_VERSION.
    if [ "$(grep -c "MARKETING_VERSION: \"$CI_TAG\"" project.yml)" -ne 1 ]; then
        echo "error: couldn't set MARKETING_VERSION to $CI_TAG in project.yml" >&2
        exit 1
    fi
    echo "MARKETING_VERSION set to $CI_TAG"
fi

xcodegen generate
