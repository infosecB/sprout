import SwiftData
import SwiftUI

/// The tabs, plus the plumbing every screen shares: links from widgets, the appearance setting and
/// keeping the widget snapshot and reminders current.
struct RootView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Plant.name) private var plants: [Plant]

    /// `-demoTab plants` opens on that tab, for screenshots.
    @State private var tab = UserDefaults.standard.string(forKey: "demoTab").flatMap(AppTab.init(rawValue:)) ?? .today
    @State private var showPaywall = false

    var body: some View {
        // Reading the plants here means any change to them (a watering, a new schedule) changes the
        // snapshot, which saves it for the widgets and reschedules the reminders.
        let snapshot = WidgetSync.snapshot(plants: plants, isPro: store.isPro)
        TabView(selection: $tab) {
            TodayView(showPaywall: $showPaywall)
                .tabItem { Label("Today", systemImage: "drop.fill") }
                .tag(AppTab.today)
            PlantsView(showPaywall: $showPaywall)
                .tabItem { Label("Plants", systemImage: "leaf.fill") }
                .tag(AppTab.plants)
            SettingsView(showPaywall: $showPaywall)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(Brand.accent)
        .preferredColorScheme(settings.appearance.colorScheme)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onOpenURL { url in
            if let target = AppLink.tab(for: url) { tab = target }
        }
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            if let parked = PendingNavigation.take() { tab = parked }
            // A new day can change what's due.
            WidgetSync.push(WidgetSync.snapshot(plants: plants, isPro: store.isPro))
        }
        .onChange(of: snapshot) { WidgetSync.push(snapshot) }
        .onChange(of: settings.remindersOn) { WidgetSync.push(snapshot) }
        .onChange(of: settings.reminderMinutes) { WidgetSync.push(snapshot) }
        .task { WidgetSync.push(snapshot) }
    }
}

#Preview {
    RootView()
        .environment(Store())
        .environment(AppSettings())
        .modelContainer(PlantStore.container)
}
