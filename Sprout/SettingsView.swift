import SwiftUI

struct SettingsView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings
    @Binding var showPaywall: Bool
    @State private var notificationsBlocked = false

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

                Section {
                    Toggle(isOn: Binding(get: { settings.remindersOn }, set: setReminders)) {
                        Label("Daily care reminder", systemImage: "bell.fill")
                    }
                    if settings.remindersOn {
                        DatePicker("Time", selection: $settings.reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    if notificationsBlocked {
                        Text("Notifications are off for Sprout. Turn them on in the Settings app.")
                    } else {
                        Text("One notification on days when plants need care.")
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
            .task {
                let allowed = await Reminders.isAllowed()
                if settings.askedForReminders && !allowed {
                    notificationsBlocked = true
                    settings.remindersOn = false
                }
            }
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

extension SettingsView {
    private func setReminders(_ on: Bool) {
        guard on else {
            settings.remindersOn = false
            return
        }
        Task {
            settings.askedForReminders = true
            var allowed = await Reminders.isAllowed()
            if !allowed { allowed = await Reminders.requestPermission() }
            settings.remindersOn = allowed
            notificationsBlocked = !allowed
            if !allowed, let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                await UIApplication.shared.open(url)
            }
        }
    }
}

#Preview {
    SettingsView(showPaywall: .constant(false))
        .environment(Store())
        .environment(AppSettings())
}
