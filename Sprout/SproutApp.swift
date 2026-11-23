import SwiftUI

@main
struct SproutApp: App {
    @State private var store = Store()
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(settings)
        }
    }
}
