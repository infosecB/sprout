import SwiftData
import SwiftUI

@main
struct SproutApp: App {
    @State private var store = Store()
    @State private var settings = AppSettings()

    init() {
        SproutShortcuts.updateAppShortcutParameters()
        // Screen titles in the display serif, to match headings inside the screens.
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.font: Brand.uiFont(34)]
        bar.titleTextAttributes = [.font: Brand.uiFont(17)]
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
