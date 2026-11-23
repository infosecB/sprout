import SwiftUI

/// The app's web pages (GitHub Pages, from this repo's `docs/` folder). App Review requires the
/// privacy policy to be reachable from inside the app, not only from the App Store page.
enum AppWeb {
    static let home = URL(string: "https://infosecb.github.io/sprout/")!
    static let privacy = URL(string: "https://infosecb.github.io/sprout/privacy/")!
    static let support = URL(string: "https://infosecb.github.io/sprout/support/")!
}

/// "Privacy Policy · Support", for the foot of the paywall.
struct AboutLinks: View {
    var body: some View {
        HStack(spacing: 18) {
            Link("Privacy Policy", destination: AppWeb.privacy)
            Link("Support", destination: AppWeb.support)
        }
        .font(.footnote.weight(.medium))
        .foregroundStyle(.secondary)
    }
}

extension Bundle {
    /// "1.0 (12)", for the About section.
    var versionDescription: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }
}
