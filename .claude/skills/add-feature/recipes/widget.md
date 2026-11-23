# Widget data or a new widget

The widgets never read the app's state. The app resolves everything into `WidgetSnapshot`
(`Shared/WidgetSnapshot.swift`), saves it to the App Group and reloads timelines only when it changed.

1. **Snapshot**: add fields with defaults (or optionals) so snapshots saved by older versions still
   decode. Keep it small and already formatted where it helps (but keep numbers as numbers if the widget
   computes anything, like "days since").
2. **Fill it** in `RootView.updateWidgets()`, and call that wherever the data changes (after saving a
   record, after an App Intent runs). It's cheap: it compares before reloading.
3. **Draw it** in `StatusWidget` (or a new widget in `SproutWidgets/`, added to the
   `WidgetBundle`). Per family:
   - `systemSmall` / `systemMedium`: `Brand` colours and fonts, `.containerBackground(for: .widget)`;
   - `accessoryRectangular` / `accessoryCircular` / `accessoryInline`: monochrome, no backgrounds,
     system fonts, keep it to the one number that matters.
   Widgets can't animate or use custom button styles; buttons need `.buttonStyle(.plain)` and an App
   Intent. Keep the Pro lock (`snapshot.isPro`).
4. **Time-based changes** (midnight rollover, countdowns): return several timeline entries or a
   `.after(date)` policy instead of `.never`, and store raw dates in the snapshot so the widget can
   compute without the app.
5. **Deep links**: `.widgetURL(AppLink.url(.tab))`; for per-element links in medium widgets use
   `Link(destination:)`. New destinations go in `AppLink`.
6. **Previews**: update the `#Preview(as:)` entries and `WidgetSnapshot.placeholder`.
7. **Verify**: run the app once (to write the snapshot), then add the widget on the simulator's Home
   Screen and screenshot it. This also gives you `4-widgets.png` for the App Store.
