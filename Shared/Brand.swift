import SwiftUI

/// The app's look, in one place. Every screen and widget takes its colours and type from here, so a
/// new app gets its own personality by editing this file (and `AccentColor` in the asset catalog,
/// which `new-app` sets to the same colour).
///
/// Keep it free of app-only types: the widget extension compiles it too.
enum Brand {
    /// The signature colour: buttons, highlights, the paywall, the icon and the website.
    static let accent = Color(red: 0.784, green: 0.392, blue: 0.231)
    /// Text and symbols drawn on top of `accent`.
    static let onAccent = Color.white

    /// Screen background. Dynamic, so it works in light and dark mode.
    static let background = Color(uiColor: .systemGroupedBackground)
    /// Cards and grouped rows on top of `background`.
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)

    /// Display type: headings, big numbers, the paywall title.
    static func font(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// The edge margin for a screen of `size`: roomier on an iPad or an unfolded iPhone Duo.
    static func margin(for size: CGSize) -> CGFloat {
        min(size.width, size.height) >= 600 ? 32 : 20
    }

    /// Squarish or landscape, such as the iPhone Duo's cover screen or a phone on its side. Use it to
    /// switch to side-by-side layouts.
    static func isWide(_ size: CGSize) -> Bool {
        size.width > size.height * 0.9
    }
}

extension View {
    /// A rounded card on `Brand.surface`.
    func card(padding: CGFloat = 18) -> some View {
        self.padding(padding)
            .background(Brand.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
