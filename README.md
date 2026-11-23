# Sprout

Water, feed and repot every houseplant on time, with a care log for each one.

Sprout is a free download for iPhone and iPad with a one-time **Sprout Pro** in-app purchase.
Website and support: <https://infosecb.github.io/sprout>.

## Features

Features marked **(Pro)** need [Sprout Pro](#sprout-pro).

- **Home**: describe the main screen.
- **Widgets** (Pro): Sprout on the Home Screen and Lock Screen, and (iOS 18) a Control Center
  control that opens the app. Without Pro, a widget shows a lock.
- **Settings**: light, dark or system appearance, unlock or restore Pro, support and privacy links.

## Sprout Pro

A one-time, non-consumable purchase (`com.brendanchamberlain.sprout.pro`) that unlocks:

- the widgets
- list the rest here, matching `Sprout/ProFeatures.swift`

## Building

Needs Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```sh
xcodegen generate
open Sprout.xcodeproj
```

Pro can be bought in the simulator from `Sprout.storekit` at no cost. See [RELEASING.md](RELEASING.md)
for TestFlight and the App Store.

## How it works

| Path | What's there |
|---|---|
| `project.yml` | Targets, build settings, bundle ID, signing team (XcodeGen) |
| `Sprout/` | The app: `SproutApp`, `RootView` (tabs), screens, `Store` (StoreKit 2), `PaywallView`, `ProFeatures`, `AppSettings`, `About` (web links) |
| `Shared/` | Compiled into the app and the widgets: `Brand` (look), `WidgetSnapshot`, `SharedDefaults` (App Group), `AppLink` (URLs and intents) |
| `SproutWidgets/` | Widget bundle, the status widget and the iOS 18 control |
| `SproutTests/` | Swift Testing unit tests |
| `Config/` | Info.plist additions and entitlements |
| `docs/` | The website (GitHub Pages): home, privacy, support |
| `appstore/` | Screenshot capture and framing scripts; listing copy is in `APPSTORE.md` |
| `scripts/` | `run-app.sh` (build and launch in the simulator), `check-consistency.py` (duplicated facts and listing limits) |
| `.claude/` | Claude Code hooks, permissions and skills |
| `ci_scripts/`, `.github/workflows/release.yml` | Xcode Cloud setup and the tag-based release workflow |

## Privacy

Sprout collects no data. See [PRIVACY.md](PRIVACY.md).
