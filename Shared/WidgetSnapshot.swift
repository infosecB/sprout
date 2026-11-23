import Foundation

/// What the widgets show. The widgets never read the app's own state: the app resolves everything
/// they need (including whether Pro is unlocked) into this snapshot, saves it to the App Group and
/// reloads the timelines when it changes. The widgets only read it.
///
/// Add the fields your widgets need. Give new fields defaults (or make them optional) so a snapshot
/// saved by an older version still decodes.
struct WidgetSnapshot: Codable, Equatable {
    var isPro: Bool = false
    /// The big line on the widget.
    var headline: String = "Sprout"
    /// The smaller line under it.
    var detail: String = "Tap to open"
    var updated: Date = .distantPast

    static let placeholder = WidgetSnapshot(isPro: true, headline: "Sprout", detail: "Your summary here")

    private static let key = "widgetSnapshot"

    static func load(from defaults: UserDefaults = SharedDefaults.store) -> WidgetSnapshot {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(WidgetSnapshot.self, from: $0) }
            ?? WidgetSnapshot()
    }

    /// Saves the snapshot. Returns false if nothing but `updated` changed, so the caller can skip
    /// reloading the widgets.
    @discardableResult
    func save(to defaults: UserDefaults = SharedDefaults.store) -> Bool {
        var old = Self.load(from: defaults)
        old.updated = updated
        guard old != self, let data = try? JSONEncoder().encode(self) else { return false }
        defaults.set(data, forKey: Self.key)
        return true
    }
}
