---
name: run-app
description: Build Sprout and launch it in the iOS Simulator, optionally on a given device (iPhone, iPhone Duo, iPad) with Pro unlocked, a tab picked or settings preset, then look at it. Use to run, start, show or screenshot the app, or to confirm a UI change actually works.
---

# Run Sprout in the simulator

1. If the user wants to watch, open the live simulator panel first (the iOS Simulator tool's
   `attach`), before building.
2. Build, install and launch:

   ```sh
   scripts/run-app.sh                         # booted simulator, else iPhone 18 Pro
   scripts/run-app.sh "iPhone Duo" -- -demoPro YES -demoTab settings
   ```

   The last line printed is the simulator's UDID. Launch arguments after `--`:
   - `-demoPro YES`: Pro unlocked without a purchase (Debug only)
   - `-demoTab <home|settings|…>`: the starting tab (`AppTab` in `Shared/AppLink.swift`)
   - any `UserDefaults` key, e.g. `-appearance dark`
   - add `-demo…` flags in `#if DEBUG` when a screen needs sample data, and list them here
3. Look before you report: take a screenshot with the iOS Simulator tool (or
   `xcrun simctl io <udid> screenshot <file>` and Read it) and check the change is visible and laid out
   well. Open deep links with `xcrun simctl openurl <udid> sprout://settings`.
4. Layout changes: also check the iPhone Duo folded (cover screen, squarish, `Brand.isWide`) and
   unfolded, an iPad, dark mode and a large Dynamic Type size
   (`xcrun simctl ui <udid> content_size extra-extra-extra-large`, reset with `large`).

If the build fails, fix it and run again rather than reporting the failure as the result. On Linux
there's no simulator: say so and stop.
