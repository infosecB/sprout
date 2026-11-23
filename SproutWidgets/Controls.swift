import AppIntents
import SwiftUI
import WidgetKit

/// A Control Center / Lock Screen / Action button control that opens the app.
@available(iOS 18.0, *)
struct OpenAppControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "OpenApp") {
            ControlWidgetButton(action: OpenAppIntent()) {
                Label("Sprout", systemImage: "sparkles")
            }
        }
        .displayName("Open Sprout")
    }
}
