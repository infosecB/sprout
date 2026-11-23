# Siri, Shortcuts and Spotlight (App Intents)

Moderate's intents (`Moderate/Intents/` in `~/gh/moderate`) are the reference: logging by voice,
checking progress, entities with queries, `AppShortcutsProvider` phrases.

1. **Where it lives**: intents only the app runs go in `Sprout/Intents/`. An intent a widget button
   or control runs must compile in both targets, so it goes in `Shared/` and may only touch shared code
   (the App Group, `WidgetSnapshot`), like `OpenAppIntent`.
2. **The intent**: `struct DoThingIntent: AppIntent` with a `title`, `@Parameter`s, and
   `perform() async throws -> some IntentResult & ProvidesDialog` returning `.result(dialog:)`. It runs
   off the main actor: hop to `MainActor` to touch app state, and do irreversible work last. Ask
   `requestConfirmation` before deleting anything.
3. **Opening the app**: set `openAppWhenRun = true` and park the destination with
   `PendingNavigation.park(_:)`; `RootView` picks it up when the app becomes active.
4. **Pro**: if the action is Pro, check the cached `isPro` (`UserDefaults.standard.bool(forKey: "isPro")`)
   and return a dialog that explains it needs Sprout Pro rather than failing silently.
5. **Phrases**: an `AppShortcutsProvider` (one per app) with `AppShortcut(intent:phrases:shortTitle:systemImageName:)`.
   Every phrase must contain `\(.applicationName)`. Phrases work with no setup by the user.
6. **Entities** (things the user can name, like a preset or a record): `AppEntity` with a stable `id`,
   an `EntityQuery` with `entities(for:)` and `suggestedEntities()`. Only `@Property` members are visible
   to Shortcuts.
7. **After it runs**: update anything the widgets show (save a new `WidgetSnapshot` and
   `WidgetCenter.shared.reloadAllTimelines()`).
8. **Docs**: README section listing each phrase ("Hey Siri, … in Sprout"), and the listing.

For newer API (iOS 26/27 `supportedModes`, snippets, Visual Intelligence), use the
`xcode-integration:app-intents-specialist` and `app-intents-whats-new-27` skills if available.
