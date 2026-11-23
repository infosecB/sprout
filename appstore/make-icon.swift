// Draws Sprout's app icon: a terracotta pot with a two-leaf sprout. 1024 × 1024 and opaque (App Store
// Connect rejects icons with an alpha channel), in the three iOS 18 appearances.
//
//     swift appstore/make-icon.swift              # writes the asset catalog icons and docs/assets/icon.png
//
// The colours match Brand (Shared/Brand.swift): accent for the pot, leaf for the sprout.

import AppKit
import SwiftUI

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let iconSet = root.appendingPathComponent("Sprout/Assets.xcassets/AppIcon.appiconset")

enum Variant: String, CaseIterable {
    case light = "AppIcon"
    case dark = "AppIcon-Dark"
    case tinted = "AppIcon-Tinted"
}

func rgb(_ hex: UInt32) -> Color {
    Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
}

/// A leaf from `base` to `tip`, `width` across at its widest, curving to one side by `bend`.
func leaf(from base: CGPoint, to tip: CGPoint, width: CGFloat, bend: CGFloat = 0) -> Path {
    let dx = tip.x - base.x, dy = tip.y - base.y
    let length = hypot(dx, dy)
    let normal = CGPoint(x: -dy / length, y: dx / length)
    func point(_ t: CGFloat, _ side: CGFloat) -> CGPoint {
        CGPoint(x: base.x + dx * t + normal.x * side, y: base.y + dy * t + normal.y * side)
    }
    var path = Path()
    path.move(to: base)
    path.addCurve(to: tip, control1: point(0.25, width * 0.95 + bend), control2: point(0.75, width * 0.75 + bend))
    path.addCurve(to: base, control1: point(0.75, -width * 0.55 + bend), control2: point(0.25, -width * 0.8 + bend))
    path.closeSubpath()
    return path
}

/// The centre vein of a leaf.
func vein(from base: CGPoint, to tip: CGPoint, bend: CGFloat) -> Path {
    let dx = tip.x - base.x, dy = tip.y - base.y
    let length = hypot(dx, dy)
    let normal = CGPoint(x: -dy / length, y: dx / length)
    var path = Path()
    path.move(to: base)
    path.addQuadCurve(to: CGPoint(x: base.x + dx * 0.82, y: base.y + dy * 0.82),
                      control: CGPoint(x: base.x + dx * 0.45 + normal.x * (bend + 18), y: base.y + dy * 0.45 + normal.y * (bend + 18)))
    return path
}

struct Icon: View {
    let variant: Variant

    // Palette per appearance. Tinted icons are greyscale; iOS applies the tint.
    var background: [Color] {
        switch variant {
        case .light: [rgb(0xFAF1E6), rgb(0xEFDCC6)]
        case .dark: [rgb(0x2A2520), rgb(0x16130F)]
        case .tinted: [rgb(0x000000), rgb(0x000000)]
        }
    }
    var potLight: Color { variant == .tinted ? rgb(0x8A8A8A) : rgb(0xDB774C) }
    var potDark: Color { variant == .tinted ? rgb(0x5E5E5E) : rgb(0xB0512C) }
    var rimLight: Color { variant == .tinted ? rgb(0xA8A8A8) : rgb(0xE5875C) }
    var rimDark: Color { variant == .tinted ? rgb(0x777777) : rgb(0xC8643B) }
    var leafLight: Color { variant == .tinted ? rgb(0xFFFFFF) : rgb(0x93CC6E) }
    var leafDark: Color { variant == .tinted ? rgb(0xD6D6D6) : rgb(0x3F8A50) }
    var stem: Color { variant == .tinted ? rgb(0xCFCFCF) : rgb(0x4F8A5B) }
    var veinColor: Color { variant == .tinted ? rgb(0x9A9A9A) : rgb(0xD8F0C4).opacity(0.75) }

    var body: some View {
        ZStack {
            LinearGradient(colors: background, startPoint: .top, endPoint: .bottom)

            // Soft glow behind the plant.
            if variant != .tinted {
                Circle()
                    .fill(RadialGradient(colors: [(variant == .light ? Color.white : rgb(0x4F8A5B)).opacity(variant == .light ? 0.7 : 0.18), .clear],
                                         center: .center, startRadius: 0, endRadius: 360))
                    .frame(width: 760, height: 760)
                    .position(x: 512, y: 430)
            }

            Canvas { context, _ in
                // Ground shadow.
                if variant != .tinted {
                    context.fill(Path(ellipseIn: CGRect(x: 302, y: 858, width: 420, height: 60)),
                                 with: .color(.black.opacity(variant == .light ? 0.10 : 0.35)))
                }

                // Stem: rises from the soil and leans a little right.
                var stemPath = Path()
                stemPath.move(to: CGPoint(x: 512, y: 600))
                stemPath.addCurve(to: CGPoint(x: 532, y: 392), control1: CGPoint(x: 500, y: 520), control2: CGPoint(x: 540, y: 450))
                context.stroke(stemPath, with: .color(stem), style: StrokeStyle(lineWidth: 34, lineCap: .round))

                // Leaves: a smaller one to the left, a bigger one up and to the right.
                let leaves: [(CGPoint, CGPoint, CGFloat, CGFloat)] = [
                    (CGPoint(x: 516, y: 450), CGPoint(x: 236, y: 318), 118, -10),
                    (CGPoint(x: 530, y: 372), CGPoint(x: 820, y: 168), 150, 14),
                ]
                for (base, tip, width, bend) in leaves {
                    let shape = leaf(from: base, to: tip, width: width, bend: bend)
                    context.fill(shape, with: .linearGradient(Gradient(colors: [leafLight, leafDark]),
                                                              startPoint: CGPoint(x: tip.x, y: tip.y - 60),
                                                              endPoint: base))
                    context.stroke(vein(from: base, to: tip, bend: bend), with: .color(veinColor),
                                   style: StrokeStyle(lineWidth: 12, lineCap: .round))
                }

                // Pot body: a tapered trapezoid with rounded bottom corners.
                var body = Path()
                body.move(to: CGPoint(x: 290, y: 640))
                body.addLine(to: CGPoint(x: 734, y: 640))
                body.addLine(to: CGPoint(x: 680, y: 850))
                body.addQuadCurve(to: CGPoint(x: 646, y: 880), control: CGPoint(x: 674, y: 880))
                body.addLine(to: CGPoint(x: 378, y: 880))
                body.addQuadCurve(to: CGPoint(x: 344, y: 850), control: CGPoint(x: 350, y: 880))
                body.closeSubpath()
                context.fill(body, with: .linearGradient(Gradient(colors: [potLight, potDark]),
                                                         startPoint: CGPoint(x: 300, y: 640), endPoint: CGPoint(x: 734, y: 880)))
                // The rim's shadow on the body.
                context.drawLayer { layer in
                    layer.clip(to: body)
                    layer.fill(Path(CGRect(x: 280, y: 640, width: 464, height: 26)), with: .color(.black.opacity(0.12)))
                }

                // Rim.
                let rim = Path(roundedRect: CGRect(x: 250, y: 560, width: 524, height: 92), cornerRadius: 30)
                context.fill(rim, with: .linearGradient(Gradient(colors: [rimLight, rimDark]),
                                                        startPoint: CGPoint(x: 250, y: 560), endPoint: CGPoint(x: 774, y: 652)))
                // Highlight along the top of the rim.
                let shine = Path(roundedRect: CGRect(x: 282, y: 574, width: 300, height: 14), cornerRadius: 7)
                context.fill(shine, with: .color(.white.opacity(variant == .tinted ? 0.25 : 0.3)))
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

func render(_ variant: Variant) throws -> Data {
    try MainActor.assumeIsolated {
        let renderer = ImageRenderer(content: Icon(variant: variant))
        renderer.scale = 1
        guard let image = renderer.cgImage,
              let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        else { throw CocoaError(.fileWriteUnknown) }
        context.draw(image, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
        guard let opaque = context.makeImage(),
              let png = NSBitmapImageRep(cgImage: opaque).representation(using: .png, properties: [:])
        else { throw CocoaError(.fileWriteUnknown) }
        return png
    }
}

for variant in Variant.allCases {
    let png = try render(variant)
    try png.write(to: iconSet.appendingPathComponent("\(variant.rawValue).png"))
    if variant == .light {
        try png.write(to: root.appendingPathComponent("docs/assets/icon.png"))
    }
    print("wrote \(variant.rawValue).png")
}
