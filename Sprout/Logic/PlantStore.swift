import Foundation
import SwiftData

/// The one model container, shared by the UI and by Siri and Shortcuts actions, so a plant watered
/// by voice shows up on screen straight away. Plants stay on the device.
@MainActor
enum PlantStore {
    static let container: ModelContainer = {
        #if DEBUG
        // Screenshot mode: `-demoData YES` fills a throwaway in-memory store with sample plants.
        if UserDefaults.standard.bool(forKey: "demoData") {
            let container = make(inMemory: true)
            DemoData.fill(container.mainContext)
            return container
        }
        #endif
        return make(inMemory: false)
    }()

    static func make(inMemory: Bool) -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: Plant.self, CareEvent.self, configurations: configuration)
        } catch {
            fatalError("Couldn't open the plant store: \(error)")
        }
    }

    static func plants(in context: ModelContext) -> [Plant] {
        (try? context.fetch(FetchDescriptor<Plant>(sortBy: [SortDescriptor(\.name)]))) ?? []
    }
}

#if DEBUG
/// Sample plants for screenshots and previews.
@MainActor
enum DemoData {
    static func fill(_ context: ModelContext, now: Date = .now) {
        let calendar = Calendar.current
        func ago(_ days: Int, hour: Int = 9) -> Date {
            let day = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now))!
            return calendar.date(byAdding: .hour, value: hour, to: day)!
        }
        // (name, species, room, symbol, tint, water every, feed every, last watered, last fed)
        let rows: [(String, String, String, String, Int, Int, Int, Int, Int?)] = [
            ("Monstera", "Monstera deliciosa", "Living room", "leaf.fill", 0, 7, 28, 7, 30),
            ("Fiddle Leaf Fig", "Ficus lyrata", "Living room", "tree.fill", 1, 7, 30, 9, 12),
            ("Pothos", "Epipremnum aureum", "Kitchen", "laurel.leading", 3, 5, 21, 2, 22),
            ("Snake Plant", "Dracaena trifasciata", "Bedroom", "leaf.fill", 4, 14, 0, 10, nil),
            ("Calathea", "Calathea orbifolia", "Bathroom", "camera.macro", 2, 4, 30, 3, 8),
            ("String of Pearls", "Curio rowleyanus", "Kitchen", "laurel.trailing", 5, 10, 0, 4, nil),
            ("Peace Lily", "Spathiphyllum", "Bedroom", "camera.macro", 1, 6, 30, 6, 40),
        ]
        for row in rows {
            let plant = Plant(name: row.0, species: row.1, room: row.2, symbol: row.3, tint: row.4,
                              waterEvery: row.5, feedEvery: row.6, created: ago(120))
            context.insert(plant)
            // A few months of history, ending on the last watering.
            var day = row.7
            while day < 110 {
                let event = CareEvent(kind: .water, date: ago(day, hour: 8 + day % 4))
                context.insert(event)
                event.plant = plant
                day += row.5
            }
            if let fed = row.8 {
                let event = CareEvent(kind: .feed, date: ago(fed), note: "Half-strength liquid feed")
                context.insert(event)
                event.plant = plant
            }
        }
        if let monstera = try? context.fetch(FetchDescriptor<Plant>(predicate: #Predicate { $0.name == "Monstera" })).first {
            monstera.notes = "Bright, indirect light. Let the top few cm dry out between waterings."
            for (kind, days, note) in [(CareKind.repot, 45, "Moved up to a 30 cm terracotta pot"),
                                       (.note, 12, "New leaf unfurling, first one with fenestrations!"),
                                       (.prune, 60, "Trimmed a yellow lower leaf")] {
                let event = CareEvent(kind: kind, date: ago(days, hour: 18), note: note)
                context.insert(event)
                event.plant = monstera
            }
        }
        try? context.save()
    }
}
#endif
