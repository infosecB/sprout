---
name: release-preflight
description: Get Sprout ready to ship and, only with the user's go-ahead, start the release (the GitHub Release workflow that tags main for Xcode Cloud). Use when the user wants to release, ship, cut a version, or send a build to TestFlight or the App Store.
---

# Release preflight

Everything before step 5 only reads or tests. Step 5 publishes; never run it without an explicit yes
in this conversation for this version.

1. **Repo state**: `git fetch origin`, then check the branch is `main`, the tree is clean, and `main`
   matches `origin/main`. If not, stop and say what's off (unpushed commits need the user to push or
   allow a push).
2. **Checks**:
   - `scripts/check-consistency.py`: no errors (fix them per the consistency-check skill, then commit).
   - Build and test:
     `xcodebuild test -project Sprout.xcodeproj -scheme Sprout -destination 'platform=iOS Simulator,name=iPhone 18 Pro' CODE_SIGNING_ALLOWED=NO -quiet`
   - The checked-in project is current: `xcodegen generate` leaves `git status` clean.
3. **Version**: latest release tag `git tag --list | sort -V | tail -n1` (bare `MAJOR.MINOR.PATCH`, no
   `v`). Summarise what changed since it (`git log <tag>..main --oneline`) and propose patch, minor or
   major. Draft "What's New" for `APPSTORE.md` from those commits, in user terms, and the release notes.
   If the `app-store-connect` tools are available, also run `app_status` for `com.brendanchamberlain.sprout`:
   the in-app purchase should be approved or ready to submit, and no version should be stuck in review.
4. **Ask** the user, in one message: the version to release, the What's New text, and anything the
   checks flagged. Also remind them of anything App Store Connect needs first (screenshots if the UI
   changed, App Privacy answers if privacy changed, the IAP attached to the version on a first release).
5. **Release** (only after a clear yes):

   ```sh
   gh workflow run release.yml --ref main -f bump=<patch|minor|major>    # or -f version=1.2.0
   gh run list --workflow release.yml --limit 1
   gh run watch <run id>
   ```

   The workflow tags `main` and creates the GitHub release; the tag starts the Xcode Cloud *Release*
   workflow, which archives and sends the build to TestFlight. Report the tag and the release URL
   (`gh release view <version> --json url`).
6. **Follow the build** (if the `app-store-connect` tools are available): `xcode_cloud_runs` shows the
   archive run for the tag; once `list_builds` shows the build `VALID`, offer to set its TestFlight
   notes (`set_testflight_notes`, from the release notes), create the App Store version if it doesn't
   exist (`create_app_version`), and push What's New and any changed listing text from `APPSTORE.md`
   (`get_listing` to compare, then `update_listing`). Each of these asks first. Submitting for review
   stays with the user in App Store Connect.
7. **After**: point the user at the TestFlight checklist in `RELEASING.md` ("Each release", step 2),
   then the submission steps. Commit the updated What's New in `APPSTORE.md` if it changed.
