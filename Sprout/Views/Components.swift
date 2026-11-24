import PhotosUI
import SwiftUI

/// A plant's photo, or its symbol in its colour on a pale wash of it, in a circle.
struct PlantAvatar: View {
    let plant: Plant
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let data = plant.photo, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                let tint = Brand.plantTint(plant.tint)
                Image(systemName: plant.symbol)
                    .font(.system(size: size * 0.42, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(tint.opacity(0.16))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

/// The small outlined "PRO" tag on locked controls.
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(Brand.accent)
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .overlay(Capsule().strokeBorder(Brand.accent.opacity(0.6), lineWidth: 1))
            .accessibilityLabel("Sprout Pro")
    }
}

/// A round button that logs one kind of care: the care's colour on a pale wash of it. `quiet` drops
/// the colour, for tasks that aren't due yet.
struct CareButton: View {
    let kind: CareKind
    var size: CGFloat = 44
    var quiet = false
    let action: () -> Void

    var body: some View {
        let color = quiet ? Color.secondary : kind.color
        Button(action: action) {
            Image(systemName: kind.symbol)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(color.opacity(quiet ? 0.10 : 0.15), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Log \(kind.label.lowercased())")
    }
}

/// A small-caps label above a group, like a heading in a field notebook.
struct SectionTitle: View {
    let title: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            trailing
        }
        .padding(.horizontal, 4)
    }
}

/// A hairline between rows inside a card, inset to line up with the text.
struct RowDivider: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle().fill(Brand.hairline).frame(height: 0.5).padding(.leading, inset)
    }
}

/// The symbols a plant without a photo can use.
enum PlantSymbols {
    static let all = ["leaf.fill", "laurel.leading", "laurel.trailing", "tree.fill", "camera.macro", "carrot.fill"]
}

enum ImageData {
    /// Loads a picked photo, shrunk to at most `maxSide` points and saved as JPEG so the store stays small.
    static func load(_ item: PhotosPickerItem, maxSide: CGFloat = 1400) async -> Data? {
        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return nil }
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

/// A short "Watered Monstera · Undo" banner after a quick log.
struct UndoBanner: View {
    let text: String
    let undo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Brand.leaf)
            Text(text).font(.subheadline.weight(.semibold)).lineLimit(1)
            Spacer(minLength: 8)
            Button("Undo", action: undo).font(.subheadline.weight(.bold))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Brand.radius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Brand.radius, style: .continuous).strokeBorder(Brand.hairline, lineWidth: 0.5))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
