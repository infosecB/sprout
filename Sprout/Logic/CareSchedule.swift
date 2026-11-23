import Foundation
import SwiftData

/// A bit of scheduled care: water this plant, due on a day.
struct CareTask: Identifiable, Hashable {
    let plant: Plant
    let kind: CareKind
    /// The start of the day it's due.
    let due: Date

    var id: String { "\(plant.id)-\(kind.rawValue)" }
}

/// When care is due. Everything works in whole days: watering "every 7 days" means seven calendar
/// days after the last watering, whatever time of day it was.
enum CareSchedule {
    /// The day care is next due: `every` days after the day it was last done, or the day the plant
    /// was added if it never has been.
    static func nextDue(last: Date?, every: Int, created: Date, calendar: Calendar = .current) -> Date {
        guard let last else { return calendar.startOfDay(for: created) }
        let day = calendar.startOfDay(for: last)
        return calendar.date(byAdding: .day, value: max(every, 1), to: day) ?? day
    }

    /// Whole days from `now` to `due`: negative when overdue, 0 when due today.
    static func days(until due: Date, from now: Date = .now, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)).day ?? 0
    }

    /// "Today", "Tomorrow", "In 3 days", "1 day late".
    static func describe(_ due: Date, from now: Date = .now, calendar: Calendar = .current) -> String {
        let days = days(until: due, from: now, calendar: calendar)
        switch days {
        case ..<(-1): return "\(-days) days late"
        case -1: return "1 day late"
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "In \(days) days"
        }
    }

    /// "today", "yesterday", "9 days ago".
    static func ago(_ date: Date, from now: Date = .now, calendar: Calendar = .current) -> String {
        switch -days(until: date, from: now, calendar: calendar) {
        case ...0: "today"
        case 1: "yesterday"
        case let days: "\(days) days ago"
        }
    }

    /// Every scheduled task for `plants`, soonest first. Feeding is a Pro schedule, so it's only
    /// included with `includeFeeding`.
    static func tasks(for plants: [Plant], includeFeeding: Bool, calendar: Calendar = .current) -> [CareTask] {
        let kinds: [CareKind] = includeFeeding ? [.water, .feed] : [.water]
        return plants.flatMap { plant in
            kinds.compactMap { kind in
                plant.nextDue(kind, calendar: calendar).map { CareTask(plant: plant, kind: kind, due: $0) }
            }
        }
        .sorted { ($0.due, $0.plant.name, $0.kind.rawValue) < ($1.due, $1.plant.name, $1.kind.rawValue) }
    }

    /// Whether a task needs doing on `now`'s day (due today or overdue).
    static func isDue(_ task: CareTask, now: Date = .now, calendar: Calendar = .current) -> Bool {
        days(until: task.due, from: now, calendar: calendar) <= 0
    }
}

/// Writing to the care log.
@MainActor
enum CareLog {
    @discardableResult
    static func log(_ kind: CareKind, for plant: Plant, on date: Date = .now, note: String = "", photo: Data? = nil,
                    in context: ModelContext) -> CareEvent {
        let event = CareEvent(kind: kind, date: date, note: note, photo: photo)
        context.insert(event)
        event.plant = plant
        try? context.save()
        return event
    }

    static func remove(_ event: CareEvent, in context: ModelContext) {
        context.delete(event)
        try? context.save()
    }
}

/// What the free version limits. Pro lifts both.
enum FreeLimits {
    /// Plants you can have without Pro.
    static let plants = 5
    /// Days of care history shown per plant without Pro. Older entries are kept, just hidden.
    static let historyDays = 30

    /// The part of `history` (newest first) a free user sees, and how many older entries are hidden.
    static func visibleHistory(_ history: [CareEvent], isPro: Bool, now: Date = .now,
                               calendar: Calendar = .current) -> (shown: [CareEvent], hidden: Int) {
        guard !isPro,
              let cutoff = calendar.date(byAdding: .day, value: -historyDays, to: calendar.startOfDay(for: now))
        else { return (history, 0) }
        let shown = history.filter { $0.date >= cutoff }
        return (shown, history.count - shown.count)
    }
}
