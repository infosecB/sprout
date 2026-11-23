import SwiftUI

struct SettingsView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings
    @Binding var showPaywall: Bool

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section {
                    if store.isPro {
                        Label("Sprout Pro is unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Brand.accent)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Unlock Sprout Pro", systemImage: "star.circle.fill")
                        }
                        Button("Restore Purchases") {
                            Task { await store.restore() }
                        }
                    }
                }

                Section("Appearance") {
                    Picker("Appearance", selection: $settings.appearance) {
                        ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section("About") {
                    Link(destination: AppWeb.support) {
                        Label("Support", systemImage: "questionmark.circle")
                    }
                    Link(destination: AppWeb.privacy) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    LabeledContent("Version", value: Bundle.main.versionDescription)
                }
            }
            .navigationTitle("Settings")
            .alert("Sprout Pro", isPresented: Binding(
                get: { store.errorMessage != nil && !showPaywall },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    SettingsView(showPaywall: .constant(false))
        .environment(Store())
        .environment(AppSettings())
}
