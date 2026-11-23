# Releasing to the App Store

## One-time setup

1. **Developer account.** The Apple Developer Program is required to sign App Groups and upload. Check
   `DEVELOPMENT_TEAM` in `project.yml` is your team (Xcode → Settings → Accounts).
2. **Identifiers.** Build once on a device from Xcode so automatic signing registers the app ID
   `com.brendanchamberlain.sprout`, the widget's `com.brendanchamberlain.sprout.widgets` and the App Group
   `group.com.brendanchamberlain.sprout`. Check them in Certificates, Identifiers & Profiles if Xcode Cloud
   complains.
3. **Agreements.** App Store Connect → Business: the *Paid Apps* agreement, banking and tax must be
   **Active** before an in-app purchase can be created or sold. It can take a day.
4. **App record.** Apps → + → New App: iOS, bundle ID `com.brendanchamberlain.sprout`, any unique SKU. Create
   it before the first upload, under a unique App Store name (`APPSTORE.md`); otherwise Xcode tries to
   name it after the display name, which may be taken.
5. **In-app purchase.** Monetization → In-App Purchases → + → Non-Consumable, product ID
   `com.brendanchamberlain.sprout.pro`. Fill it in from `APPSTORE.md`, including a **review screenshot** of the
   paywall (`appstore/screenshots/raw/<size>/iap-review-paywall.png`). It must be "Ready to Submit".
6. **App Privacy.** "No, we do not collect data from this app", matching `PrivacyInfo.xcprivacy`.
7. **Website.** The privacy and support URLs are required. In the GitHub repo: Settings → Pages →
   *Deploy from a branch*, `main`, `/docs`. The site is served at https://infosecb.github.io/sprout/. Pages from a private repo needs a paid GitHub plan.
8. **Xcode Cloud.** Product → Xcode Cloud → Create Workflow, called *Release*:
   - **Start condition:** *Tag Changes* → *Any Tag*. Remove the default *Branch Changes* condition.
   - **Action:** *Archive*, iOS, scheme `Sprout`, deployment preparation *App Store Connect*.
   - **Post-action:** *TestFlight (Internal Testing)*.

## Each release

1. On GitHub, **Actions → Release → Run workflow** on `main` (*patch*, *minor*, *major* or an exact
   version). It tags `main` and publishes a GitHub release; the tag starts Xcode Cloud, and
   `ci_scripts/ci_post_clone.sh` sets `MARKETING_VERSION` from it. Xcode Cloud sets the build number.
2. Test the TestFlight build on a real device:
   - [ ] Free tier: Pro features show the paywall; widgets show a lock
   - [ ] Buy Pro with a Sandbox account; everything unlocks without relaunching, widgets within seconds
   - [ ] Delete, reinstall, **Restore Purchases**
   - [ ] Widgets and the Control Center control open the app
   - [ ] Rotate, iPad, iPhone Duo folded and unfolded, light/dark, larger text, Reduce Motion
3. Screenshots and artwork:
   ```sh
   appstore/take-screenshots.sh
   swift appstore/frame-screenshots.swift
   ```
   Save the widget screenshot (`4-widgets.png`) and the paywall (`iap-review-paywall.png`) by hand
   with ⌘S into each size's `raw` folder, then run the frame script again. Upload
   `screenshots/framed/<size>/` in order to the matching device tab, and `creative/` to the product
   page header and search results.
4. Fill in the listing from `APPSTORE.md`, pick the build, and **add Sprout Pro under In-App
   Purchases on the version page** (the first IAP must be submitted with an app version).
5. Paste the review notes from `APPSTORE.md` and submit.
