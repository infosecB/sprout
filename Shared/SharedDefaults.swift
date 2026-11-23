import Foundation

/// The App Group the app and its widgets share.
///
/// Its name is set once, in `project.yml` (`APP_GROUP_IDENTIFIER`), and reaches the code through the
/// `AppGroupIdentifier` Info.plist key, so nothing here has to change for a new app.
enum SharedDefaults {
    static let appGroup = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String ?? ""
    static let store = UserDefaults(suiteName: appGroup) ?? .standard
}
