import PhotosUI
import SwiftData
import SwiftUI

/// Logs care with a date, a note and (Pro) a progress photo.
struct LogCareSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let plant: Plant
    @State var kind: CareKind
    @State private var date = Date.now
    @State private var note = ""
    @State private var photo: Data?
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Care", selection: $kind) {
                        ForEach(CareKind.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                    DatePicker("When", selection: $date, in: ...Date.now)
                }
                Section("Note") {
                    TextField(placeholder, text: $note, axis: .vertical)
                        .lineLimit(2...6)
                }
                Section {
                    if store.isPro {
                        PhotosPicker(selection: $pickedPhoto, matching: .images) {
                            Label(photo == nil ? "Add Progress Photo" : "Change Photo", systemImage: "camera")
                        }
                        if let photo, let image = UIImage(data: photo) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    } else {
                        Button { showPaywall = true } label: {
                            HStack {
                                Label("Add Progress Photo", systemImage: "camera")
                                Spacer()
                                ProBadge()
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } footer: {
                    Text("Photos build a growth timeline on the plant's page.")
                }
            }
            .navigationTitle(plant.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        CareLog.log(kind, for: plant, on: date, note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                                    photo: store.isPro ? photo : nil, in: context)
                        dismiss()
                    }
                    .disabled(kind == .note && note.trimmingCharacters(in: .whitespaces).isEmpty && photo == nil)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: pickedPhoto) {
                guard let pickedPhoto else { return }
                Task { photo = await ImageData.load(pickedPhoto) }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var placeholder: String {
        switch kind {
        case .repot: "New pot size, soil mix…"
        case .prune: "What you trimmed"
        case .note: "New leaf, pests, moved spot…"
        default: "Optional"
        }
    }
}
