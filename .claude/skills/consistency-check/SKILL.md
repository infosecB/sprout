---
name: consistency-check
description: Check that facts duplicated across Sprout's files still agree (Pro product ID and price, Pro feature list, accent colour, website URLs, privacy policy copies, privacy manifest and usage descriptions vs the APIs used) and that the App Store listing fits its limits, then fix what's off. Use after changing Pro features, privacy-relevant code, the listing or the brand colour, and before any release.
---

# Consistency check

1. Run it:

   ```sh
   scripts/check-consistency.py
   ```

   Errors are what App Review or the build would catch the hard way; warnings need a human look.
2. Fix each **error** at its source, keeping every copy in step:

   | Fact | Where it lives |
   |---|---|
   | Pro product ID | `Store.proID`, `Sprout.storekit`, `APPSTORE.md`, `RELEASING.md` |
   | Pro price | `Sprout.storekit` `displayPrice`, `APPSTORE.md` |
   | What Pro unlocks | `ProFeatures.swift`, README "Sprout Pro", `APPSTORE.md` description, storekit description (≤55 chars) |
   | Accent colour | `Shared/Brand.swift`, `AccentColor` asset, `docs/assets/style.css`, `appstore/frame-screenshots.swift` |
   | Website | `AppWeb` in `About.swift`, `docs/CNAME`, `APPSTORE.md` URLs |
   | Privacy | `PRIVACY.md` ↔ `docs/privacy/index.html` (same points and date), both `PrivacyInfo.xcprivacy`, App Privacy answers in App Store Connect |
   | Usage descriptions | `INFOPLIST_KEY_…` in `project.yml` for each protected API |

   When the code starts using something privacy-relevant (Health, location, camera, network, a
   required-reason API), update the manifest, both privacy policy copies (new "Last updated" date in
   both) and the usage string, and tell the user the App Privacy answers in App Store Connect may need
   to change. Don't change those answers' meaning on your own: ask.
3. Look at each **warning** and fix it or explain why it's fine.
4. Run the script again until it reports no errors, and say what you changed.

If the `app-store-connect` tools are available, also compare `get_listing` with `APPSTORE.md` and say
what differs (the listing in App Store Connect is what users see). Offer to push the repo's copy with
`update_listing`, or to update `APPSTORE.md` from the live listing; don't do either without a yes.

The script can't judge tone or truth: also read the listing description and make sure every Pro feature
is marked as needing Sprout Pro (guideline 2.3.2) and nothing is promised that the app doesn't do.
