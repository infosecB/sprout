import SwiftUI
import WidgetKit

/// The tabs, plus the plumbing every screen shares: links from widgets, the appearance setting and
/// keeping the widget snapshot current.
struct RootView: View {
    @Environment(Store.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase

    /// `-demoTab settings` opens on that tab, for screenshots.
    @State private var tab = UserDefaults.standard.string(forKey: "demoTab").flatMap(AppTab.init(rawValue:)) ?? .home
    @State private var showPaywall = false

    var body: some View {
        TabView(selection: $tab) {
            HomeView(showPaywall: $showPaywall)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(AppTab.home)
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
            updateWidgets()
        }
        .onChange(of: store.isPro) { updateWidgets() }
        .task { updateWidgets() }
    }

    /// Resolves what the widgets show and reloads them if it changed. Call it whenever anything the
    /// widgets display changes.
    private func updateWidgets() {
        let snapshot = WidgetSnapshot(
            isPro: store.isPro,
            headline: "Sprout",
            detail: store.isPro ? "Pro unlocked" : "Tap to open",
            updated: .now
        )
        if snapshot.save() {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

#Preview {
    RootView()
        .environment(Store())
        .environment(AppSettings())
}
