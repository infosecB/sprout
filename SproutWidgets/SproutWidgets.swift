import SwiftUI
import WidgetKit

/// Everything the widget extension offers.
@main
struct SproutWidgets: WidgetBundle {
    var body: some Widget {
        StatusWidget()
        if #available(iOS 18.0, *) {
            OpenAppControl()
        }
    }
}
