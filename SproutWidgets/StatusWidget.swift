import SwiftUI
import WidgetKit

struct StatusEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

/// Reads the snapshot the app wrote. The app reloads the timeline whenever it changes; between
/// those, an entry at each of the next few midnights moves tomorrow's watering into "today" without
/// the app running.
struct StatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatusEntry {
        StatusEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatusEntry) -> Void) {
        completion(StatusEntry(date: .now, snapshot: context.isPreview ? .placeholder : .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let midnights = (1...7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        let entries = [StatusEntry(date: .now, snapshot: snapshot)] + midnights.map { StatusEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .after(midnights.last ?? today)))
    }
}

/// Home Screen (small, medium) and Lock Screen (circular, rectangular, inline) widget showing which
/// plants need care today. Pro only: without Pro it shows a lock, and tapping it opens the app.
struct StatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Status", provider: StatusProvider()) { entry in
            StatusWidgetView(snapshot: entry.snapshot, date: entry.date)
                .containerBackground(for: .widget) { Brand.background }
                .widgetURL(AppLink.url(.today))
        }
        .configurationDisplayName("Plant Care")
        .description("Which plants need water or feeding today.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct StatusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: WidgetSnapshot
    let date: Date

    private var due: [WidgetSnapshot.CareItem] { snapshot.due(on: date) }
    private var plantsDue: Int { Set(due.map(\.plant)).count }

    var body: some View {
        if !snapshot.isPro {
            locked
        } else {
            switch family {
            case .accessoryInline:
                Label(inlineText, systemImage: "drop.fill")
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        Image(systemName: plantsDue == 0 ? "checkmark" : "drop.fill").font(.caption)
                        if plantsDue > 0 { Text("\(plantsDue)").font(.title3.weight(.bold)) }
                    }
                }
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 1) {
                    Text(headline).font(.headline).widgetAccentable()
                    Text(names(limit: 3)).font(.caption).lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .systemMedium:
                HStack(alignment: .top, spacing: 14) {
                    summary.frame(maxWidth: 120, alignment: .leading)
                    VStack(alignment: .leading, spacing: 7) {
                        if due.isEmpty {
                            Spacer(minLength: 0)
                            Text(nextText).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                        }
                        ForEach(Array(due.prefix(4).enumerated()), id: \.offset) { _, item in
                            HStack(spacing: 7) {
                                Image(systemName: item.kind.symbol)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(item.kind.color)
                                    .frame(width: 16)
                                Text(item.plant).font(.subheadline.weight(.semibold)).lineLimit(1)
                            }
                        }
                        if due.count > 4 {
                            Text("+\(due.count - 4) more").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            default:
                summary.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: plantsDue == 0 ? "checkmark.circle.fill" : "drop.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(plantsDue == 0 ? Brand.leaf : Brand.water)
            Spacer(minLength: 0)
            Text(plantsDue == 0 ? "All good" : "\(plantsDue)")
                .font(Brand.font(plantsDue == 0 ? 22 : 34, weight: .heavy))
                .minimumScaleFactor(0.7)
            Text(plantsDue == 0 ? nextText : plantsDue == 1 ? "plant needs care" : "plants need care")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private var headline: String {
        plantsDue == 0 ? "Plants all good" : plantsDue == 1 ? "1 plant needs care" : "\(plantsDue) plants need care"
    }

    private var inlineText: String {
        plantsDue == 0 ? "Plants all good" : "\(plantsDue) to care for"
    }

    private var nextText: String {
        guard let next = snapshot.next(after: date) else { return snapshot.plantCount == 0 ? "Add a plant" : "Nothing due" }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: date), to: next.due).day ?? 0
        return "\(next.plant) \(days == 1 ? "tomorrow" : "in \(days) days")"
    }

    private func names(limit: Int) -> String {
        guard !due.isEmpty else { return nextText }
        var seen: [String] = []
        for item in due where !seen.contains(item.plant) { seen.append(item.plant) }
        let shown = seen.prefix(limit).joined(separator: ", ")
        return seen.count > limit ? "\(shown) +\(seen.count - limit)" : shown
    }

    @ViewBuilder private var locked: some View {
        switch family {
        case .accessoryInline:
            Label("Sprout Pro", systemImage: "lock.fill")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "lock.fill")
            }
        default:
            VStack(spacing: 6) {
                Image(systemName: "lock.fill").font(.title3)
                Text("Sprout Pro").font(.caption.weight(.semibold))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview(as: .systemSmall) {
    StatusWidget()
} timeline: {
    StatusEntry(date: .now, snapshot: .placeholder)
    StatusEntry(date: .now, snapshot: WidgetSnapshot())
}

#Preview(as: .systemMedium) {
    StatusWidget()
} timeline: {
    StatusEntry(date: .now, snapshot: .placeholder)
}
