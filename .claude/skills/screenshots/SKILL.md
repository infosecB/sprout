---
name: screenshots
description: Take and frame Sprout's App Store screenshots and header/search artwork with the appstore/ scripts, report what's missing, and show the results. Use when the user asks for App Store screenshots, marketing images or creative assets, or before a release.
---

# App Store screenshots

1. Make sure each screenshot shows something real: the `SHOTS` list in `appstore/take-screenshots.sh`
   stages each screen with launch arguments. If a screen needs sample data, add a `-demo…` flag (read in
   `#if DEBUG`) that fills it, rather than leaving empty states in the shots. Keep the file names
   (`N-name`) in step with `screenshots` in `appstore/frame-screenshots.swift`, and rewrite the captions
   there for this app: a short phrase that adds to what the screen shows, not a description of it. The
   first three show in search results, so they carry the main idea.
2. Capture (default sizes: iPhone 18 Pro 1206×2622, iPhone Duo outer and inner, iPad 13"):

   ```sh
   appstore/take-screenshots.sh </dev/null      # </dev/null skips the Duo inner display prompt
   ```

   The Duo's inner display needs the simulator unfolded in Xcode; run the script from a terminal for
   that, or ask the user to. Pass device types to shoot fewer sizes.
3. Frame and make the artwork:

   ```sh
   swift appstore/frame-screenshots.swift
   ```

4. Report:
   - which sizes were taken and which shots were skipped. `4-widgets.png` (Home/Lock Screen widgets)
     and `iap-review-paywall.png` (the in-app purchase's review screenshot) must be taken by hand with
     ⌘S into each size's `appstore/screenshots/raw/<size>/` folder; then run the frame script again.
   - Show two or three framed screenshots and `appstore/creative/header-21x9.png` (scale them down with
     `sips -Z 800 <in> --out <tmp>` and Read them) and check captions aren't clipped and nothing shows
     placeholder text, debug UI or an empty state.
5. Upload order: `appstore/screenshots/framed/<size>/` in numeric order to the matching device tab;
   `creative/header-21x9.png` to Header, `creative/search-3x2.png` to Search Results.
