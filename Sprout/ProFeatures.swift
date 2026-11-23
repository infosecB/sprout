/// What Sprout Pro unlocks, as the paywall lists it. Keep it in step with the README's
/// "Sprout Pro" section, the storekit description and the App Store listing: App Review rejects
/// listings that present paid features as free.
struct ProFeature: Hashable {
    let icon: String
    let title: String
    let detail: String
}

extension ProFeature {
    static let all = [
        ProFeature(icon: "square.grid.2x2.fill", title: "Widgets",
                   detail: "See Sprout at a glance on your Home Screen and Lock Screen."),
        ProFeature(icon: "sparkles", title: "Every feature",
                   detail: "Replace these with what Pro really unlocks."),
        ProFeature(icon: "heart.fill", title: "Support an indie developer",
                   detail: "One purchase, no subscription, no ads."),
    ]
}
