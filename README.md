# Sprout

Water, feed and repot every houseplant on time, with a care log for each one.

Sprout is a free download for iPhone and iPad with a one-time **Sprout Pro** in-app purchase.
Website and support: <https://infosecb.github.io/sprout>.

## Features

Features marked **(Pro)** need [Sprout Pro](#sprout-pro).

- **Today**: which plants need water today (and which are late), one tap to log it with undo, a
  "Do all" button, and what's coming up this week.
- **Plants**: every plant, grouped by room, with when it next needs water. Up to 5 plants free;
  unlimited plants (Pro).
- **Plant page**: watering schedule, quick buttons to log watering, feeding, misting, repotting,
  pruning and notes, and the care log. The last 30 days of history are free; full history (Pro).
- **Feeding reminders** (Pro): a fertilising schedule alongside watering.
- **Growth photos** (Pro): progress photos on log entries, shown as a timeline on the plant's page.
- **Reminders**: one notification a day at a time you pick, only on days something needs care.
- **Siri and Shortcuts**: "Water the Monstera in Sprout", "What needs water in Sprout?".
- **Widgets** (Pro): who needs care today on the Home Screen and Lock Screen, and (iOS 18) a Control
  Center control that opens the app. Without Pro, a widget shows a lock.
- **Settings**: reminder time, light, dark or system appearance, unlock or restore Pro, support and
  privacy links.

## Sprout Pro

A one-time, non-consumable purchase (`com.brendanchamberlain.sprout.pro`) that unlocks:

- unlimited plants (free: 5)
- feeding reminders
- growth photos in the care log
- full care history (free: the last 30 days)
- the widgets

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
| `Sprout/` | The app: `SproutApp`, `RootView` (tabs), `Store` (StoreKit 2), `PaywallView`, `ProFeatures`, `AppSettings`, `About` (web links) |
| `Sprout/Models/` | SwiftData models: `Plant` and `CareEvent` |
| `Sprout/Logic/` | `CareSchedule` (what's due, `CareLog`, `FreeLimits`), `PlantStore` (the model container and `-demoData`), `Reminders` (notifications), `WidgetSync` |
| `Sprout/Views/` | Today, Plants, plant page, plant editor, log sheet, shared components |
| `Sprout/Intents/` | Siri and Shortcuts: Water Plant, What Needs Care |
| `Shared/` | Compiled into the app and the widgets: `Brand` (look), `CareKind`, `WidgetSnapshot`, `SharedDefaults` (App Group), `AppLink` (URLs and intents) |
| `SproutWidgets/` | Widget bundle, the status widget and the iOS 18 control |
| `SproutTests/` | Swift Testing unit tests |
| `Config/` | Info.plist additions and entitlements |
| `docs/` | The website (GitHub Pages): home, privacy, support |
| `appstore/` | Screenshot capture and framing scripts, `make-icon.swift` (draws the app icon in light, dark and tinted: `swift appstore/make-icon.swift`); listing copy is in `APPSTORE.md` |
| `scripts/` | `run-app.sh` (build and launch in the simulator), `check-consistency.py` (duplicated facts and listing limits) |
| `.claude/` | Claude Code hooks, permissions and skills |
| `ci_scripts/`, `.github/workflows/release.yml` | Xcode Cloud setup and the tag-based release workflow |

## Siri and Shortcuts

- "Water *plant* in Sprout" / "I watered *plant* in Sprout": logs a watering.
- "What needs water in Sprout?" / "Check my plants in Sprout": says what needs care today.

## Screenshot mode

Debug builds take launch arguments: `-demoData YES` (sample plants in a throwaway store), `-demoPro YES`,
`-demoTab today|plants|settings`, `-demoPlant Monstera` (opens that plant on the Plants tab).

## Privacy

Sprout collects no data. See [PRIVACY.md](PRIVACY.md).
