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

    /// Water: watering tasks and the drop button.
    static let water = Color(red: 0.231, green: 0.510, blue: 0.769)
    /// Feeding (fertiliser) tasks.
    static let feed = Color(red: 0.788, green: 0.584, blue: 0.157)
    /// Healthy and done: "All caught up", pruning.
    static let leaf = Color(red: 0.310, green: 0.541, blue: 0.357)

    /// Screen background: a warm, potting-shed cream in light mode, the system's in dark mode.
    static let background = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .systemGroupedBackground
            : UIColor(red: 0.969, green: 0.949, blue: 0.925, alpha: 1)
    })
    /// Cards and grouped rows on top of `background`.
    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? .secondarySystemGroupedBackground : .white
    })

    /// Fill colours for plants without a photo, picked per plant (`Plant.tint`).
    static let plantTints: [Color] = [
        leaf,
        Color(red: 0.494, green: 0.627, blue: 0.459),   // sage
        accent,
        Color(red: 0.337, green: 0.549, blue: 0.533),   // eucalyptus
        Color(red: 0.588, green: 0.420, blue: 0.565),   // orchid
        feed,
    ]

    static func plantTint(_ index: Int) -> Color {
        plantTints[((index % plantTints.count) + plantTints.count) % plantTints.count]
    }

    /// Display type: headings, plant names, big numbers. A serif (New York) gives Sprout the feel of
    /// a field guide or a gardener's notebook; body text stays in the system sans. Serifs look clumsy
    /// above semibold, so heavier weights are capped there.
    static func font(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        let capped: Font.Weight = [.bold, .heavy, .black].contains(weight) ? .semibold : weight
        return .system(size: size, weight: capped, design: .serif)
    }

    /// The `UIFont` twin of `font(_:weight:)`, for navigation bar titles.
    static func uiFont(_ size: CGFloat, weight: UIFont.Weight = .semibold) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        return base.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: size) } ?? base
    }

    /// Corner radius for grouped surfaces. Kept modest so the screen reads as paper, not bubbles.
    static let radius: CGFloat = 14
    /// The thin edge around surfaces and between rows, used instead of drop shadows.
    static let hairline = Color.primary.opacity(0.08)

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
    /// A grouped surface on `Brand.surface` with a hairline edge. Group related rows inside one card
    /// rather than giving every row its own.
    func card(padding: CGFloat = 18) -> some View {
        let shape = RoundedRectangle(cornerRadius: Brand.radius, style: .continuous)
        return self.padding(padding)
            .background(Brand.surface, in: shape)
            .overlay(shape.strokeBorder(Brand.hairline, lineWidth: 0.5))
    }
}
