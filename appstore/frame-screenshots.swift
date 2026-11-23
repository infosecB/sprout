// Adds captions to the raw screenshots and draws the product page header and search results artwork,
// on the app's accent colour (Brand.accent in Shared/Brand.swift).
//
//     swift appstore/frame-screenshots.swift
//
// Reads each size folder in appstore/screenshots/raw (from take-screenshots.sh) and writes the same
// folder in appstore/screenshots/framed, numbered in upload order, plus appstore/creative from the
// iPhone screenshots. Missing screenshots are skipped. Every file is an opaque PNG: App Store Connect
// turns down screenshots and artwork with an alpha channel, and simulator screenshots have one.

import AppKit
import SwiftUI

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let raw = root.appending(path: "screenshots/raw")
let framed = root.appending(path: "screenshots/framed")
let creative = root.appending(path: "creative")

// MARK: - Edit these

let appName = "Sprout"
let tagline = "Water, feed and repot every houseplant on time, with a care log for each one."
/// Brand.accent.
let accent = Color(red: 0.784, green: 0.392, blue: 0.231)
let night = Color(red: 0.07, green: 0.07, blue: 0.10)

struct Screenshot {
    let file: String
    /// A short phrase that adds to what the screen shows rather than describing it.
    let caption: String
    let detail: String
    var pro = false
    var dark = false
}

/// In upload order. The first three show in search results, so they carry the main idea.
let screenshots = [
    Screenshot(file: "1-today", caption: "Who's thirsty\ntoday?", detail: "One tap to log every watering"),
    Screenshot(file: "2-plant", caption: "A care log for\nevery plant", detail: "Water, feed, repot, prune and notes"),
    Screenshot(file: "3-plants-dark", caption: "Your whole\njungle", detail: "Grouped by room, light or dark", dark: true),
    Screenshot(file: "4-widgets", caption: "At a glance", detail: "Home Screen and Lock Screen widgets", pro: true),
]
/// The iPhone screenshots the header and search artwork show, middle one in front.
let creativePhones = ["2-settings", "1-home", "3-home-dark"]

// MARK: - Look

func displayFont(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy, design: .rounded) }

struct Backdrop: View {
    var dark = false
    var body: some View {
        LinearGradient(colors: dark ? [night, accent.opacity(0.55)] : [accent.opacity(0.8), accent],
                       startPoint: .top, endPoint: .bottom)
            .background(Color.black)
    }
}

struct Phone: View {
    let image: NSImage
    let width: CGFloat

    var body: some View {
        let height = width * image.size.height / image.size.width
        let radius = min(width, height / 2.17) * 0.125
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .frame(width: width, height: height)
            .clipShape(shape)
            .overlay(shape.strokeBorder(Color.black.opacity(0.85), lineWidth: width * 0.018))
            .shadow(color: .black.opacity(0.3), radius: width * 0.04, y: width * 0.02)
    }
}

struct ProTag: View {
    let size: CGFloat
    var body: some View {
        Text("PRO")
            .font(displayFont(size))
            .tracking(size * 0.06)
            .foregroundStyle(accent)
            .padding(.horizontal, size * 0.55)
            .padding(.vertical, size * 0.16)
            .background(Color.white, in: Capsule())
    }
}

struct ScreenshotFrame: View {
    let shot: Screenshot
    let image: NSImage
    let size: CGSize

    var body: some View {
        // Laid out for the 1206 × 2622 iPhone and scaled for other sizes; wider screens scale text with
        // the height and give the device whatever width fits under the caption.
        let k = min(size.width / 1206, size.height / 2200)
        let captionRoom = 620 * k
        let aspect = image.size.height / image.size.width
        let phoneWidth = min(size.width * 0.80, (size.height - captionRoom - 90 * k) / aspect)
        VStack(spacing: 0) {
            VStack(spacing: 28 * k) {
                if shot.pro { ProTag(size: 40 * k) }
                Text(shot.caption)
                    .font(displayFont(112 * k))
                    .lineSpacing(-10 * k)
                    .multilineTextAlignment(.center)
                Text(shot.detail)
                    .font(.system(size: 46 * k, weight: .semibold, design: .rounded))
                    .opacity(0.85)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.white)
            .padding(.top, 120 * k)
            .padding(.horizontal, 80 * k)
            Spacer(minLength: 0)
            Phone(image: image, width: phoneWidth)
                .padding(.bottom, 80 * k)
        }
        .frame(width: size.width, height: size.height)
        .background(Backdrop(dark: shot.dark))
    }
}

/// The icon, name and tagline beside (wide) or above (squarer) three phones that run off the bottom.
struct Creative: View {
    let size: CGSize
    let icon: NSImage
    let phones: [NSImage]

    private var isWide: Bool { size.width / size.height >= 1.7 }
    private var unit: CGFloat { size.height / 100 }
    private var margin: CGFloat { size.width * 0.08 }

    var body: some View {
        Group {
            if isWide {
                HStack(spacing: 0) {
                    title(alignment: .leading, scale: 1)
                        .frame(width: size.width * 0.42, alignment: .leading)
                        .padding(.leading, margin)
                    Spacer(minLength: 0)
                    phoneRow(width: (size.width * 0.58 - margin * 1.4) / 3.25)
                        .padding(.trailing, margin * 0.7)
                        .frame(height: size.height, alignment: .top)
                        .padding(.top, size.height * 0.30)
                }
            } else {
                VStack(spacing: 0) {
                    title(alignment: .center, scale: 0.8).padding(.top, size.height * 0.08)
                    phoneRow(width: size.width * 0.235).padding(.top, size.height * 0.07)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(width: size.width, height: size.height, alignment: .top)
        .background(Backdrop())
        .clipped()
    }

    private func title(alignment: HorizontalAlignment, scale: CGFloat) -> some View {
        let unit = unit * scale
        return VStack(alignment: alignment, spacing: unit * 3) {
            Image(nsImage: icon)
                .resizable()
                .frame(width: unit * 16, height: unit * 16)
                .clipShape(RoundedRectangle(cornerRadius: unit * 3.6, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: unit, y: unit * 0.5)
            Text(appName).font(displayFont(unit * 14))
            Text(tagline)
                .font(.system(size: unit * 5, weight: .semibold, design: .rounded))
                .multilineTextAlignment(alignment == .center ? .center : .leading)
                .frame(maxWidth: unit * 80, alignment: alignment == .center ? .center : .leading)
        }
        .foregroundStyle(.white)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func phoneRow(width: CGFloat) -> some View {
        HStack(alignment: .top, spacing: width * 0.12) {
            ForEach(Array(phones.enumerated()), id: \.offset) { index, phone in
                Phone(image: phone, width: width)
                    .rotationEffect(.degrees(index == 0 ? -3 : index == 2 ? 3 : 0))
                    .offset(y: index == 1 ? -width * 0.18 : 0)
            }
        }
    }
}

// MARK: - Rendering

@MainActor
func write<V: View>(_ view: V, size: CGSize, to url: URL) throws {
    let renderer = ImageRenderer(content: view.frame(width: size.width, height: size.height))
    renderer.scale = 1
    renderer.proposedSize = ProposedViewSize(size)
    guard let image = renderer.cgImage else { throw CocoaError(.fileWriteUnknown) }
    let width = Int(size.width), height = Int(size.height)
    guard let context = CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { throw CocoaError(.fileWriteUnknown) }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let opaque = context.makeImage(),
          let png = NSBitmapImageRep(cgImage: opaque).representation(using: .png, properties: [:])
    else { throw CocoaError(.fileWriteUnknown) }
    try png.write(to: url)
    print("  \(url.lastPathComponent)  \(width) × \(height)")
}

func load(_ url: URL) -> NSImage? {
    guard let image = NSImage(contentsOf: url), let rep = image.representations.first else { return nil }
    image.size = CGSize(width: rep.pixelsWide, height: rep.pixelsHigh)
    return image
}

@MainActor
func main() throws {
    let files = FileManager.default
    try files.createDirectory(at: creative, withIntermediateDirectories: true)

    let sizes = try files.contentsOfDirectory(at: raw, includingPropertiesForKeys: nil)
        .filter(\.hasDirectoryPath)
        .sorted { $0.lastPathComponent.compare($1.lastPathComponent, options: .numeric) == .orderedAscending }
    for folder in sizes {
        let out = framed.appending(path: folder.lastPathComponent)
        // Start empty, so a renumbered shot isn't uploaded twice.
        try? files.removeItem(at: out)
        try files.createDirectory(at: out, withIntermediateDirectories: true)
        print("Screenshots, \(folder.lastPathComponent):")
        var number = 0
        for shot in screenshots {
            guard let image = load(folder.appending(path: "\(shot.file).png")) else {
                print("  skipped \(shot.file).png: not taken yet")
                continue
            }
            number += 1
            let name = shot.file.drop(while: { $0 != "-" }).dropFirst()
            try write(ScreenshotFrame(shot: shot, image: image, size: image.size), size: image.size,
                      to: out.appending(path: "\(number)-\(name).png"))
        }
        if let paywall = load(folder.appending(path: "iap-review-paywall.png")) {
            try write(Image(nsImage: paywall).resizable(), size: paywall.size,
                      to: out.appending(path: "iap-review-paywall.png"))
        }
    }

    let iconURL = root.deletingLastPathComponent()
        .appending(path: "\(appName)/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
    guard let icon = load(iconURL) else { throw CocoaError(.fileReadNoSuchFile) }
    let iphone = raw.appending(path: "1206x2622")
    let phones = creativePhones.compactMap { load(iphone.appending(path: "\($0).png")) }
    guard phones.count == 3 else {
        print("Creative assets skipped: needs three iPhone 1206x2622 screenshots (run take-screenshots.sh)")
        return
    }
    print("Creative assets:")
    let artwork: [(String, CGSize)] = [
        ("header-21x9", CGSize(width: 3840, height: 1646)),
        ("search-3x2", CGSize(width: 3840, height: 2560)),
        ("universal-16x9", CGSize(width: 5244, height: 2950)),
    ]
    for (name, size) in artwork {
        try write(Creative(size: size, icon: icon, phones: phones), size: size,
                  to: creative.appending(path: "\(name).png"))
    }
}

try MainActor.assumeIsolated { try main() }
