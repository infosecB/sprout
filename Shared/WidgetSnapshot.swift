import Foundation

/// What the widgets show. The widgets never read the app's own state: the app resolves everything
/// they need (including whether Pro is unlocked) into this snapshot, saves it to the App Group and
/// reloads the timelines when it changes. The widgets only read it.
///
/// Give new fields defaults (or make them optional) so a snapshot saved by an older version still
/// decodes.
struct WidgetSnapshot: Codable, Equatable {
    /// One scheduled bit of care: water the Monstera, due on a day.
    struct CareItem: Codable, Equatable {
        var plant: String
        var kind: CareKind
        /// The start of the day it's due.
        var due: Date
    }

    var isPro: Bool = false
    var plantCount: Int = 0
    /// Every scheduled task for the next couple of weeks, soonest first. Widgets work out what's due
    /// on the day they're drawn, so they stay right past midnight without the app running.
    var items: [CareItem] = []
    var updated: Date = .distantPast

    /// What needs doing on `date`, including anything overdue.
    func due(on date: Date, calendar: Calendar = .current) -> [CareItem] {
        let end = calendar.startOfDay(for: date)
        return items.filter { $0.due <= end }
    }

    /// The first task after `date`.
    func next(after date: Date, calendar: Calendar = .current) -> CareItem? {
        let end = calendar.startOfDay(for: date)
        return items.first { $0.due > end }
    }

    static let placeholder: WidgetSnapshot = {
        let today = Calendar.current.startOfDay(for: .now)
        return WidgetSnapshot(isPro: true, plantCount: 6, items: [
            CareItem(plant: "Monstera", kind: .water, due: today),
            CareItem(plant: "Fiddle Leaf Fig", kind: .water, due: today),
            CareItem(plant: "Pothos", kind: .feed, due: today),
            CareItem(plant: "Snake Plant", kind: .water, due: today.addingTimeInterval(3 * 86_400)),
        ])
    }()

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
