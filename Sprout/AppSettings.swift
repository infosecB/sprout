import SwiftUI

/// Light, dark or follow the system.
enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: Self { self }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// The user's choices, saved in `UserDefaults` as they change.
///
/// Launch arguments override what's saved (`-appearance dark`), which is how
/// `appstore/take-screenshots.sh` sets up each screenshot. Add new settings the same way: a stored
/// property with a `didSet` that saves it, read back in `init`.
@MainActor @Observable
final class AppSettings {
    private let defaults: UserDefaults

    var appearance: Appearance {
        didSet { defaults.set(appearance.rawValue, forKey: "appearance") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = defaults.string(forKey: "appearance").flatMap(Appearance.init(rawValue:)) ?? .system
    }
}
