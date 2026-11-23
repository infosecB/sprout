import PhotosUI
import SwiftData
import SwiftUI

/// Adds a plant (`plant: nil`) or edits one.
struct PlantEditor: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Plant.name) private var plants: [Plant]

    let plant: Plant?
    /// Called after the plant is deleted, so the screen showing it can close.
    var onDelete: () -> Void = {}

    @State private var name = ""
    @State private var species = ""
    @State private var room = ""
    @State private var notes = ""
    @State private var symbol = PlantSymbols.all[0]
    @State private var tint = 0
    @State private var photo: Data?
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var waterEvery = 7
    @State private var feeds = false
    @State private var feedEvery = 28
    @State private var confirmDelete = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        preview
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section {
                    TextField("Name", text: $name)
                        .font(.headline)
                    TextField("Species (optional)", text: $species)
                    TextField("Room (optional)", text: $room)
                    if !otherRooms.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(otherRooms, id: \.self) { option in
                                    Button(option) { room = option }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                        .tint(room == option ? Brand.accent : .secondary)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }

                Section("Look") {
                    PhotosPicker(selection: $pickedPhoto, matching: .images) {
                        Label(photo == nil ? "Choose Photo" : "Change Photo", systemImage: "photo")
                    }
                    if photo != nil {
                        Button("Remove Photo", role: .destructive) { photo = nil }
                    } else {
                        HStack {
                            ForEach(PlantSymbols.all, id: \.self) { option in
                                Button { symbol = option } label: {
                                    Image(systemName: option)
                                        .frame(width: 34, height: 34)
                                        .foregroundStyle(symbol == option ? .white : .secondary)
                                        .background(symbol == option ? Brand.plantTint(tint) : .clear, in: Circle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(option)
                            }
                        }
                        HStack {
                            ForEach(Brand.plantTints.indices, id: \.self) { index in
                                Button { tint = index } label: {
                                    Circle()
                                        .fill(Brand.plantTints[index])
                                        .frame(width: 30, height: 30)
                                        .overlay(Circle().strokeBorder(.primary.opacity(tint == index ? 0.7 : 0), lineWidth: 3))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Colour \(index + 1)")
                            }
                        }
                    }
                }

                Section {
                    Stepper(value: $waterEvery, in: 1...60) {
                        Label("Water every \(waterEvery) \(waterEvery == 1 ? "day" : "days")", systemImage: "drop.fill")
                    }
                    if store.isPro {
                        Toggle(isOn: $feeds) {
                            Label("Feeding schedule", systemImage: "flask.fill")
                        }
                        if feeds {
                            Stepper(value: $feedEvery, in: 7...120, step: 7) {
                                Text("Feed every \(feedEvery / 7) \(feedEvery == 7 ? "week" : "weeks")")
                            }
                        }
                    } else {
                        Button { showPaywall = true } label: {
                            HStack {
                                Label("Feeding schedule", systemImage: "flask.fill")
                                Spacer()
                                ProBadge()
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("Schedule")
                } footer: {
                    Text("Most houseplants like water every 7 to 10 days; succulents and snake plants every 2 to 3 weeks.")
                }

                Section("Notes") {
                    TextField("Light, soil, where it came from…", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                if plant != nil {
                    Section {
                        Button("Delete Plant", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(plant == nil ? "New Plant" : "Edit Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(plant == nil ? "Add" : "Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Delete \(plant?.name ?? "this plant") and its care log?", isPresented: $confirmDelete,
                                titleVisibility: .visible) {
                Button("Delete Plant", role: .destructive) { delete() }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: pickedPhoto) {
                guard let pickedPhoto else { return }
                Task { photo = await ImageData.load(pickedPhoto) }
            }
            .onAppear(perform: load)
        }
    }

    private var preview: some View {
        let sample = Plant(name: name, symbol: symbol, tint: tint)
        sample.photo = photo
        return PlantAvatar(plant: sample, size: 96)
    }

    private var otherRooms: [String] {
        Array(Set(plants.map(\.room)).filter { !$0.isEmpty }).sorted()
    }

    private func load() {
        guard let plant else { return }
        name = plant.name
        species = plant.species
        room = plant.room
        notes = plant.notes
        symbol = plant.symbol
        tint = plant.tint
        photo = plant.photo
        waterEvery = plant.waterEvery
        feeds = plant.feedEvery > 0
        if plant.feedEvery > 0 { feedEvery = plant.feedEvery }
    }

    private func save() {
        let target = plant ?? Plant(name: "", tint: plants.count % Brand.plantTints.count)
        if plant == nil { context.insert(target) }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.species = species.trimmingCharacters(in: .whitespaces)
        target.room = room.trimmingCharacters(in: .whitespaces)
        target.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        target.symbol = symbol
        target.tint = tint
        target.photo = photo
        target.waterEvery = waterEvery
        // Without Pro the feeding schedule can't be edited here, so keep whatever was set.
        if store.isPro { target.feedEvery = feeds ? feedEvery : 0 }
        try? context.save()
        if plant == nil {
            Task { await settings.askForRemindersIfNeeded() }
        }
        dismiss()
    }

    private func delete() {
        guard let plant else { return }
        context.delete(plant)
        try? context.save()
        dismiss()
        onDelete()
    }
}
