---
name: add-feature
description: Recipes for the features Sprout apps keep needing, done the house way so nothing is missed - a Pro-gated feature, data in a widget, a Siri/Shortcuts action (App Intent), a new tab, and persistent records with SwiftData. Use when adding any of these to Sprout.
---

# Add a feature

Pick the recipe, read it, and do every step: the steps beyond the code (docs, listing, privacy,
screenshot flags) are what usually get missed.

| Adding… | Recipe |
|---|---|
| Something only Pro unlocks | [recipes/pro-feature.md](recipes/pro-feature.md) |
| New data on a widget, or a new widget | [recipes/widget.md](recipes/widget.md) |
| A Siri / Shortcuts / Spotlight action | [recipes/app-intent.md](recipes/app-intent.md) |
| A new tab or screen | [recipes/screen.md](recipes/screen.md) |
| Records the user creates (SwiftData) | [recipes/swiftdata.md](recipes/swiftdata.md) |

Every recipe ends the same way:

1. Build and run the tests; add a test for any logic (Swift Testing, in `SproutTests/`). The
   project regenerates itself when files are added (a hook), but commit `Sprout.xcodeproj` with the
   change.
2. Look at it with the run-app skill, including the iPhone Duo and iPad if it has UI.
3. Update the README feature list (mark Pro features "(Pro)") and its file map.
4. Run `scripts/check-consistency.py`.
