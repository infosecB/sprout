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

    /// The daily care reminder. Off until the user allows notifications.
    var remindersOn: Bool {
        didSet { defaults.set(remindersOn, forKey: "remindersOn") }
    }

    /// When the reminder goes off, in minutes after midnight.
    var reminderMinutes: Int {
        didSet { defaults.set(reminderMinutes, forKey: "reminderMinutes") }
    }

    /// Whether Sprout has asked to send notifications, which it does after the first plant is added.
    var askedForReminders: Bool {
        didSet { defaults.set(askedForReminders, forKey: "askedForReminders") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = defaults.string(forKey: "appearance").flatMap(Appearance.init(rawValue:)) ?? .system
        remindersOn = defaults.bool(forKey: "remindersOn")
        reminderMinutes = defaults.object(forKey: "reminderMinutes") as? Int ?? Self.defaultReminderMinutes
        askedForReminders = defaults.bool(forKey: "askedForReminders")
    }

    nonisolated static let defaultReminderMinutes = 9 * 60

    /// The saved reminder settings, for code that runs without the UI (Siri and Shortcuts actions).
    nonisolated static var remindersOn: Bool { UserDefaults.standard.bool(forKey: "remindersOn") }
    nonisolated static var reminderMinutes: Int {
        UserDefaults.standard.object(forKey: "reminderMinutes") as? Int ?? defaultReminderMinutes
    }

    /// The reminder time as a date today, for a `DatePicker`.
    var reminderTime: Date {
        get { Calendar.current.date(byAdding: .minute, value: reminderMinutes, to: Calendar.current.startOfDay(for: .now)) ?? .now }
        set {
            let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderMinutes = (parts.hour ?? 9) * 60 + (parts.minute ?? 0)
        }
    }

    /// Asks for notification permission once, and turns reminders on if it's granted.
    func askForRemindersIfNeeded() async {
        guard !askedForReminders else { return }
        askedForReminders = true
        remindersOn = await Reminders.requestPermission()
    }
}
