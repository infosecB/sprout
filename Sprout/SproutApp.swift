import SwiftData
import SwiftUI

@main
struct SproutApp: App {
    @State private var store = Store()
    @State private var settings = AppSettings()

    init() {
        SproutShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(settings)
        }
        .modelContainer(PlantStore.container)
    }
}
