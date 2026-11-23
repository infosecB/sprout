# A Pro feature

Sprout Pro is a one-time unlock (`Store`, StoreKit 2). The free tier must stay useful.

1. **Gate at the point of use, never by deleting state.** Read `store.isPro` (`@Environment(Store.self)`):
   - a setting that needs Pro: keep the saved value, but resolve it to the free behaviour when
     `!store.isPro` (like Tooner's `settings.current(isPro:)`), so buying Pro brings it back;
   - a locked control: still visible, shows a lock or a PRO tag (see `HomeView`), and opens the paywall
     (`showPaywall = true`) instead of acting;
   - a limit (e.g. 7 days free, 90 with Pro): clamp at display time.
   Downgrades happen (refunds, Family Sharing changes), so the free path must handle data made with Pro.
2. **Widgets**: resolve Pro into `WidgetSnapshot` (the app does the gating, never the widget).
3. **Paywall**: add a `ProFeature` to `ProFeatures.swift` (SF Symbol, short title, one-sentence detail).
   Order by appeal.
4. **Words**: README "Sprout Pro" list, `APPSTORE.md` description (in the Pro section and marked
   wherever the feature is mentioned), `Sprout.storekit` description if it's still accurate (≤55
   characters), and the review notes if a reviewer needs directions to find it.
5. **Screenshots**: if it appears in a shot, set `pro: true` on that `Screenshot` in
   `appstore/frame-screenshots.swift` (adds the PRO tag).
6. **Test**: a unit test that the free path falls back correctly, e.g. with a scratch `UserDefaults`.
