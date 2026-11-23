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
        ProFeature(icon: "leaf.fill", title: "Unlimited plants",
                   detail: "The free version looks after up to \(FreeLimits.plants). Pro has room for your whole jungle."),
        ProFeature(icon: "flask.fill", title: "Feeding reminders",
                   detail: "Put fertilising on its own schedule, alongside watering."),
        ProFeature(icon: "camera.fill", title: "Growth photos",
                   detail: "Add progress photos to the care log and watch each plant grow."),
        ProFeature(icon: "clock.arrow.circlepath", title: "Full care history",
                   detail: "Every entry, forever. Free shows the last \(FreeLimits.historyDays) days."),
        ProFeature(icon: "square.grid.2x2.fill", title: "Widgets",
                   detail: "See who's thirsty on your Home Screen and Lock Screen."),
        ProFeature(icon: "heart.fill", title: "Support an indie developer",
                   detail: "One purchase, no subscription, no ads."),
    ]
}
