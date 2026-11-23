import Foundation
import UserNotifications

/// One local notification a day, at the time chosen in Settings, on each of the next two weeks' days
/// that have care due ("3 plants need water: Monstera, Pothos and Calathea"). Rescheduled from the
/// widget snapshot whenever it changes, so watering a plant updates what tomorrow's reminder says.
enum Reminders {
    static let days = 14
    private static let prefix = "care-"

    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func isAllowed() async -> Bool {
        let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional || status == .ephemeral
    }

    /// Replaces the pending reminders with ones for `items`. `minutes` is the time of day, in minutes
    /// after midnight.
    static func schedule(_ items: [WidgetSnapshot.CareItem], enabled: Bool, minutes: Int, now: Date = .now,
                         calendar: Calendar = .current) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<days).map { "\(prefix)\($0)" })
        guard enabled else { return }
        for (offset, fire, due) in plan(items, minutes: minutes, now: now, calendar: calendar) {
            let content = UNMutableNotificationContent()
            let text = message(for: due)
            content.title = text.title
            content.body = text.body
            content.sound = .default
            content.userInfo = ["link": AppLink.url(.today).absoluteString]
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            center.add(UNNotificationRequest(identifier: "\(prefix)\(offset)", content: content, trigger: trigger))
        }
    }

    /// The reminders to schedule: for each day still ahead whose reminder time hasn't passed, what's
    /// due by then (anything not done yet stays due).
    static func plan(_ items: [WidgetSnapshot.CareItem], minutes: Int, now: Date = .now,
                     calendar: Calendar = .current) -> [(offset: Int, fire: Date, items: [WidgetSnapshot.CareItem])] {
        let today = calendar.startOfDay(for: now)
        return (0..<days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let fire = calendar.date(byAdding: .minute, value: minutes, to: day),
                  fire > now
            else { return nil }
            let due = items.filter { $0.due <= day }
            return due.isEmpty ? nil : (offset, fire, due)
        }
    }

    /// "Monstera needs water" or "4 plants need care", with the names in the body.
    static func message(for items: [WidgetSnapshot.CareItem]) -> (title: String, body: String) {
        let plants = items.map(\.plant).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        let kinds = Set(items.map(\.kind))
        let what = kinds == [.water] ? "water" : kinds == [.feed] ? "feeding" : "care"
        let title = plants.count == 1 ? "\(plants[0]) needs \(what)" : "\(plants.count) plants need \(what)"
        let names = plants.count <= 3 ? plants : Array(plants.prefix(3)) + ["\(plants.count - 3) more"]
        let list = ListFormatter.localizedString(byJoining: names)
        return (title, plants.count == 1 ? "Open Sprout to log it." : list)
    }
}
