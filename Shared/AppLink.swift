import AppIntents
import Foundation

/// The app's tabs, which `sprout://` links, the control and `-demoTab` can open.
enum AppTab: String, CaseIterable, Codable {
    case home
    case settings
}

/// `sprout://<tab>` links. Widgets open these; `RootView` handles them.
enum AppLink {
    static let scheme = "sprout"

    static func url(_ tab: AppTab) -> URL {
        URL(string: "\(scheme)://\(tab.rawValue)")!
    }

    static func tab(for url: URL) -> AppTab? {
        guard url.scheme == scheme else { return nil }
        return AppTab(rawValue: url.host() ?? "")
    }
}

/// Where a widget or control asked the app to go. An intent that opens the app parks the tab here
/// and `RootView` picks it up.
enum PendingNavigation {
    private static let key = "pendingTab"

    static func park(_ tab: AppTab) {
        SharedDefaults.store.set(tab.rawValue, forKey: key)
    }

    static func take() -> AppTab? {
        defer { SharedDefaults.store.removeObject(forKey: key) }
        return SharedDefaults.store.string(forKey: key).flatMap(AppTab.init(rawValue:))
    }
}

/// Opens the app, for the Control Center control and Shortcuts.
struct OpenAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Sprout"
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        PendingNavigation.park(.home)
        return .result()
    }
}
