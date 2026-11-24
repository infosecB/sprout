import SwiftData
import SwiftUI

/// The second tab: every plant, grouped by room.
struct PlantsView: View {
    @Environment(Store.self) private var store
    @Query(sort: \Plant.name) private var plants: [Plant]
    @Binding var showPaywall: Bool
    @State private var adding = false
    @State private var path: [Plant] = []

    var body: some View {
        GeometryReader { proxy in
            let margin = Brand.margin(for: proxy.size)
            NavigationStack(path: $path) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        if plants.isEmpty {
                            ContentUnavailableView {
                                Label("No plants yet", systemImage: "leaf")
                            } description: {
                                Text("Add a plant to start its watering schedule and care log.")
                            } actions: {
                                Button("Add a plant") { add() }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Brand.accent)
                            }
                            .padding(.top, 60)
                        }
                        ForEach(rooms, id: \.self) { room in
                            VStack(alignment: .leading, spacing: 10) {
                                if rooms.count > 1 || !room.isEmpty {
                                    SectionTitle(title: room.isEmpty ? "Other plants" : room)
                                }
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 240), spacing: 12)], spacing: 12) {
                                    ForEach(plants.filter { $0.room == room }) { plant in
                                        NavigationLink(value: plant) { PlantCard(plant: plant) }
                                            .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        if !store.isPro && !plants.isEmpty {
                            Button { showPaywall = true } label: {
                                HStack {
                                    Text("\(min(plants.count, FreeLimits.plants)) of \(FreeLimits.plants) free plants")
                                    Spacer()
                                    Text("Unlimited with Pro").foregroundStyle(Brand.accent)
                                }
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: 1000)
                    .padding(margin)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
                .background(Brand.background)
                .navigationTitle("Plants")
                .navigationDestination(for: Plant.self) { PlantDetailView(plant: $0, showPaywall: $showPaywall) }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add Plant", systemImage: "plus") { add() }
                    }
                }
                .sheet(isPresented: $adding) { PlantEditor(plant: nil) }
                #if DEBUG
                // Screenshot mode: `-demoPlant Monstera` opens that plant.
                .task {
                    if let name = UserDefaults.standard.string(forKey: "demoPlant"), path.isEmpty,
                       let plant = plants.first(where: { $0.name == name }) {
                        path = [plant]
                    }
                }
                #endif
            }
        }
    }

    /// Rooms in alphabetical order, with unsorted plants last.
    private var rooms: [String] {
        let names = Set(plants.map(\.room))
        return names.filter { !$0.isEmpty }.sorted() + (names.contains("") ? [""] : [])
    }

    private func add() {
        if !store.isPro && plants.count >= FreeLimits.plants {
            showPaywall = true
        } else {
            adding = true
        }
    }
}

private struct PlantCard: View {
    @Environment(Store.self) private var store
    let plant: Plant

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlantAvatar(plant: plant, size: 52)
            VStack(alignment: .leading, spacing: 1) {
                Text(plant.name)
                    .font(Brand.font(18))
                    .lineLimit(1)
                Text(plant.species.isEmpty ? " " : plant.species)
                    .font(Brand.font(13, weight: .regular))
                    .italic()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let due = plant.nextDue(.water) {
                let late = CareSchedule.days(until: due) <= 0
                Label(CareSchedule.describe(due), systemImage: "drop.fill")
                    .labelStyle(DueLabelStyle())
                    .font(.caption.weight(late ? .semibold : .regular))
                    .foregroundStyle(late ? Brand.water : .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 14)
    }
}

/// A small drop and a date, tighter than the default label spacing.
private struct DueLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.foregroundStyle(Brand.water)
            configuration.title
        }
    }
}
