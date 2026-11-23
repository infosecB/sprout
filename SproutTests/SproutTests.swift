import Foundation
import SwiftData
import Testing
@testable import Sprout

struct WidgetSnapshotTests {
    private func scratchDefaults() -> UserDefaults {
        let name = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func roundTrips() {
        let defaults = scratchDefaults()
        let item = WidgetSnapshot.CareItem(plant: "Monstera", kind: .water, due: .now)
        let snapshot = WidgetSnapshot(isPro: true, plantCount: 1, items: [item], updated: .now)
        #expect(snapshot.save(to: defaults))
        let loaded = WidgetSnapshot.load(from: defaults)
        #expect(loaded.items == [item])
        #expect(loaded.isPro)
    }

    @Test func skipsSavingWhenOnlyTheDateChanged() {
        let defaults = scratchDefaults()
        WidgetSnapshot(plantCount: 2, updated: .distantPast).save(to: defaults)
        #expect(!WidgetSnapshot(plantCount: 2, updated: .now).save(to: defaults))
        #expect(WidgetSnapshot(plantCount: 3, updated: .now).save(to: defaults))
    }

    @Test func dueIncludesOverdueButNotFuture() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let day = { calendar.date(byAdding: .day, value: $0, to: today)! }
        let snapshot = WidgetSnapshot(items: [
            .init(plant: "Late", kind: .water, due: day(-2)),
            .init(plant: "Today", kind: .feed, due: today),
            .init(plant: "Soon", kind: .water, due: day(3)),
        ])
        #expect(snapshot.due(on: .now).map(\.plant) == ["Late", "Today"])
        #expect(snapshot.due(on: day(3)).count == 3)
        #expect(snapshot.next(after: .now)?.plant == "Soon")
    }

    @Test func linksRoundTrip() {
        for tab in AppTab.allCases {
            #expect(AppLink.tab(for: AppLink.url(tab)) == tab)
        }
    }
}

struct ProTests {
    private struct StoreKitFile: Decodable {
        struct Product: Decodable {
            let productID: String
            let type: String
        }
        let products: [Product]
    }

    /// Sprout.storekit sells the product Store asks for, so Pro can be bought from Xcode.
    @Test func storeKitFileSellsTheProProduct() throws {
        let bundle = Bundle(for: BundleToken.self)
        let url = try #require(bundle.url(forResource: "Sprout", withExtension: "storekit"))
        let file = try JSONDecoder().decode(StoreKitFile.self, from: Data(contentsOf: url))
        let product = try #require(file.products.first { $0.productID == Store.proID })
        #expect(product.type == "NonConsumable")
    }
}

private final class BundleToken {}

private let calendar = Calendar(identifier: .gregorian)
private let monday = calendar.date(from: DateComponents(year: 2026, month: 3, day: 2, hour: 10))!
private func day(_ offset: Int, hour: Int = 10) -> Date {
    calendar.date(byAdding: .hour, value: hour - 10, to: calendar.date(byAdding: .day, value: offset, to: monday)!)!
}

struct ScheduleTests {
    @Test func neverWateredIsDueTheDayItWasAdded() {
        #expect(CareSchedule.nextDue(last: nil, every: 7, created: day(-3), calendar: calendar) == calendar.startOfDay(for: day(-3)))
    }

    @Test func countsWholeDaysFromTheLastWatering() {
        // Watered late on Monday: due the next Monday, not at 11pm.
        let due = CareSchedule.nextDue(last: day(0, hour: 23), every: 7, created: day(-30), calendar: calendar)
        #expect(due == calendar.startOfDay(for: day(7)))
        #expect(CareSchedule.days(until: due, from: day(6, hour: 23), calendar: calendar) == 1)
    }

    @Test func describesDays() {
        #expect(CareSchedule.describe(day(0), from: day(0), calendar: calendar) == "Today")
        #expect(CareSchedule.describe(day(1), from: day(0), calendar: calendar) == "Tomorrow")
        #expect(CareSchedule.describe(day(4), from: day(0), calendar: calendar) == "In 4 days")
        #expect(CareSchedule.describe(day(-1), from: day(0), calendar: calendar) == "1 day late")
        #expect(CareSchedule.describe(day(-3), from: day(0), calendar: calendar) == "3 days late")
        #expect(CareSchedule.ago(day(0, hour: 7), from: day(0), calendar: calendar) == "today")
        #expect(CareSchedule.ago(day(-1), from: day(0), calendar: calendar) == "yesterday")
        #expect(CareSchedule.ago(day(-9), from: day(0), calendar: calendar) == "9 days ago")
    }

    @MainActor @Test func feedingIsOnlyScheduledWithPro() throws {
        let container = PlantStore.make(inMemory: true)
        let context = container.mainContext
        let plant = Plant(name: "Pothos", waterEvery: 5, feedEvery: 21, created: day(-40))
        context.insert(plant)
        CareLog.log(.water, for: plant, on: day(-1), in: context)
        #expect(CareSchedule.tasks(for: [plant], includeFeeding: false, calendar: calendar).map(\.kind) == [.water])
        let pro = CareSchedule.tasks(for: [plant], includeFeeding: true, calendar: calendar)
        // Never fed, so feeding is due first (from the day it was added).
        #expect(pro.map(\.kind) == [.feed, .water])
        #expect(plant.nextDue(.water, calendar: calendar) == calendar.startOfDay(for: day(4)))
    }

    @MainActor @Test func deletingAPlantDeletesItsLog() throws {
        let container = PlantStore.make(inMemory: true)
        let context = container.mainContext
        let plant = Plant(name: "Fern")
        context.insert(plant)
        CareLog.log(.mist, for: plant, in: context)
        context.delete(plant)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<CareEvent>()) == 0)
    }
}

struct FreeLimitTests {
    @MainActor @Test func freeHistoryHidesOldEntries() {
        let container = PlantStore.make(inMemory: true)
        let context = container.mainContext
        let plant = Plant(name: "Fig")
        context.insert(plant)
        for offset in [0, -10, -29, -31, -90] {
            CareLog.log(.water, for: plant, on: day(offset), in: context)
        }
        let free = FreeLimits.visibleHistory(plant.history, isPro: false, now: day(0), calendar: calendar)
        #expect(free.shown.count == 3)
        #expect(free.hidden == 2)
        let pro = FreeLimits.visibleHistory(plant.history, isPro: true, now: day(0), calendar: calendar)
        #expect(pro.shown.count == 5 && pro.hidden == 0)
    }
}

struct ReminderTests {
    private let items: [WidgetSnapshot.CareItem] = [
        .init(plant: "Monstera", kind: .water, due: calendar.startOfDay(for: day(0))),
        .init(plant: "Pothos", kind: .water, due: calendar.startOfDay(for: day(2))),
    ]

    @Test func skipsTodayOnceTheReminderTimeHasPassed() {
        // 10am now, reminders at 9am: today's is gone, so the first is tomorrow's (Monstera still due).
        let plan = Reminders.plan(items, minutes: 9 * 60, now: day(0), calendar: calendar)
        #expect(plan.first?.offset == 1)
        #expect(plan.first?.items.map(\.plant) == ["Monstera"])
        #expect(plan.first(where: { $0.offset == 2 })?.items.count == 2)
        #expect(plan.count == Reminders.days - 1)
    }

    @Test func remindsTodayIfTheTimeIsStillAhead() {
        let plan = Reminders.plan(items, minutes: 18 * 60, now: day(0), calendar: calendar)
        #expect(plan.first?.offset == 0)
    }

    @Test func nothingDueMeansNoReminder() {
        let later = [WidgetSnapshot.CareItem(plant: "Cactus", kind: .water, due: calendar.startOfDay(for: day(5)))]
        let plan = Reminders.plan(later, minutes: 18 * 60, now: day(0), calendar: calendar)
        #expect(plan.first?.offset == 5)
    }

    @Test func messages() {
        #expect(Reminders.message(for: [items[0]]).title == "Monstera needs water")
        let many = ["A", "B", "C", "D", "E"].map { WidgetSnapshot.CareItem(plant: $0, kind: .water, due: .now) }
            + [WidgetSnapshot.CareItem(plant: "A", kind: .feed, due: .now)]
        let message = Reminders.message(for: many)
        #expect(message.title == "5 plants need care")
        #expect(message.body.contains("2 more"))
    }
}
