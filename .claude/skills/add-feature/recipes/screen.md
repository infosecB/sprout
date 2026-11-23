# A new tab or screen

1. **A tab**: add a case to `AppTab` (`Shared/AppLink.swift`); it automatically becomes a deep link
   (`sprout://<case>`) and a `-demoTab` value. Add the tab to `RootView`'s `TabView` with a
   `.tag(AppTab.x)`. Four or five tabs at most; otherwise push from an existing one.
2. **Layout**: wrap the screen in a `GeometryReader` and use `Brand.margin(for:)`; switch to a
   side-by-side layout when `Brand.isWide(size)` (iPhone Duo cover screen, landscape) and scale up when
   `min(width, height) >= 600` (unfolded Duo, iPad). Cap content width (`.frame(maxWidth: 640)`) on big
   screens. Scroll views get `.scrollBounceBehavior(.basedOnSize)`.
3. **Look**: colours and display fonts from `Brand`, cards with `.card()`. Respect
   `accessibilityReduceMotion` for continuous animation. Give icon-only buttons an
   `accessibilityLabel`.
4. **State**: preferences in `AppSettings` (stored property + `didSet` save + read in `init`, so launch
   arguments can override it); records in SwiftData (see swiftdata.md).
5. **Empty state**: a first-run user sees it, and so would a screenshot. Make it inviting, and add a
   `-demo…` flag that fills the screen with sample data for screenshots.
6. **Screenshots**: add a `shot` line in `appstore/take-screenshots.sh` and a caption in
   `appstore/frame-screenshots.swift` if the screen is worth showing.
