import AppIntents
import SwiftData

/// A plant, for Siri and Shortcuts.
struct PlantEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Plant"
    static let defaultQuery = PlantQuery()

    let id: UUID
    @Property(title: "Name") var name: String
    @Property(title: "Room") var room: String

    init(_ plant: Plant) {
        id = plant.id
        name = plant.name
        room = plant.room
    }

    var displayRepresentation: DisplayRepresentation {
        room.isEmpty ? DisplayRepresentation(title: "\(name)") : DisplayRepresentation(title: "\(name)", subtitle: "\(room)")
    }
}

struct PlantQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [PlantEntity] {
        PlantStore.plants(in: PlantStore.container.mainContext)
            .filter { identifiers.contains($0.id) }
            .map(PlantEntity.init)
    }

    @MainActor
    func entities(matching string: String) async throws -> [PlantEntity] {
        PlantStore.plants(in: PlantStore.container.mainContext)
            .filter { $0.name.localizedCaseInsensitiveContains(string) }
            .map(PlantEntity.init)
    }

    @MainActor
    func suggestedEntities() async throws -> [PlantEntity] {
        PlantStore.plants(in: PlantStore.container.mainContext).map(PlantEntity.init)
    }
}

@MainActor
private func plant(for entity: PlantEntity) -> Plant? {
    PlantStore.plants(in: PlantStore.container.mainContext).first { $0.id == entity.id }
}

/// "Water the Monstera in Sprout."
struct WaterPlantIntent: AppIntent {
    static let title: LocalizedStringResource = "Water Plant"
    static let description = IntentDescription("Logs a watering in the plant's care log.")

    @Parameter(title: "Plant") var plant: PlantEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Water \(\.$plant)")
    }

    init() {}
    init(plant: PlantEntity) { self.plant = plant }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let target = Sprout.plant(for: plant) else {
            return .result(dialog: "I couldn't find that plant in Sprout.")
        }
        let context = PlantStore.container.mainContext
        CareLog.log(.water, for: target, in: context)
        WidgetSync.refresh(context: context)
        let next = target.nextDue(.water).map { CareSchedule.describe($0).lowercased() } ?? "later"
        return .result(dialog: "Watered \(target.name). Next watering \(next).")
    }
}

/// "What needs water in Sprout?"
struct WhatNeedsCareIntent: AppIntent {
    static let title: LocalizedStringResource = "What Needs Care"
    static let description = IntentDescription("Says which plants need watering (and, with Sprout Pro, feeding) today.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let plants = PlantStore.plants(in: PlantStore.container.mainContext)
        let isPro = UserDefaults.standard.bool(forKey: "isPro")
        let due = CareSchedule.tasks(for: plants, includeFeeding: isPro).filter { CareSchedule.isDue($0) }
        guard !due.isEmpty else {
            return .result(dialog: plants.isEmpty ? "You haven't added any plants to Sprout yet." : "Nothing today. All your plants are happy.")
        }
        let items = due.map { WidgetSnapshot.CareItem(plant: $0.plant.name, kind: $0.kind, due: $0.due) }
        let message = Reminders.message(for: items)
        let names = ListFormatter.localizedString(byJoining: Array(Set(items.map(\.plant))).sorted())
        return .result(dialog: "\(message.title): \(names).")
    }
}

struct SproutShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: WaterPlantIntent(), phrases: [
            "Water \(\.$plant) in \(.applicationName)",
            "Log watering \(\.$plant) in \(.applicationName)",
            "I watered \(\.$plant) in \(.applicationName)",
        ], shortTitle: "Water Plant", systemImageName: "drop.fill")
        AppShortcut(intent: WhatNeedsCareIntent(), phrases: [
            "What needs water in \(.applicationName)",
            "Which plants need care in \(.applicationName)",
            "Check my plants in \(.applicationName)",
        ], shortTitle: "What Needs Care", systemImageName: "leaf.fill")
    }
}
