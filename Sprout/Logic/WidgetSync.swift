import Foundation
import SwiftData
import WidgetKit

/// Turns the plants into the `WidgetSnapshot`, saves it for the widgets and reschedules the
/// reminders from it. `RootView` does this whenever the snapshot changes; Siri and Shortcuts actions
/// call `refresh(context:)` because the app's UI may not be running.
@MainActor
enum WidgetSync {
    static func snapshot(plants: [Plant], isPro: Bool, now: Date = .now) -> WidgetSnapshot {
        let horizon = Calendar.current.date(byAdding: .day, value: Reminders.days, to: now) ?? now
        let items = CareSchedule.tasks(for: plants, includeFeeding: isPro)
            .filter { $0.due <= horizon }
            .map { WidgetSnapshot.CareItem(plant: $0.plant.name, kind: $0.kind, due: $0.due) }
        return WidgetSnapshot(isPro: isPro, plantCount: plants.count, items: items)
    }

    /// Saves `snapshot`, reloading the widgets if it changed, and reschedules the reminders.
    static func push(_ snapshot: WidgetSnapshot) {
        var stamped = snapshot
        stamped.updated = .now
        if stamped.save() {
            WidgetCenter.shared.reloadAllTimelines()
        }
        Reminders.schedule(snapshot.items, enabled: AppSettings.remindersOn, minutes: AppSettings.reminderMinutes)
    }

    static func refresh(context: ModelContext) {
        push(snapshot(plants: PlantStore.plants(in: context), isPro: UserDefaults.standard.bool(forKey: "isPro")))
    }
}
