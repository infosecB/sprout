import SwiftUI
import WidgetKit

struct StatusEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

/// Reads the snapshot the app wrote. The app reloads the timeline whenever it changes, so one entry
/// with `.never` is enough; return more entries if the widget must change on its own (at midnight,
/// say).
struct StatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatusEntry {
        StatusEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatusEntry) -> Void) {
        completion(StatusEntry(date: .now, snapshot: context.isPreview ? .placeholder : .load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatusEntry>) -> Void) {
        completion(Timeline(entries: [StatusEntry(date: .now, snapshot: .load())], policy: .never))
    }
}

/// Home Screen (small, medium) and Lock Screen (rectangular, inline) widget. Pro only: without Pro
/// it shows a lock, and tapping it opens the app.
struct StatusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Status", provider: StatusProvider()) { entry in
            StatusWidgetView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { Brand.background }
                .widgetURL(AppLink.url(.home))
        }
        .configurationDisplayName("Sprout")
        .description("Sprout at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct StatusWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let snapshot: WidgetSnapshot

    var body: some View {
        if !snapshot.isPro {
            locked
        } else {
            switch family {
            case .accessoryInline:
                Text(snapshot.headline)
            case .accessoryRectangular:
                VStack(alignment: .leading) {
                    Text(snapshot.headline).font(.headline)
                    Text(snapshot.detail).font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            default:
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Brand.accent)
                    Spacer(minLength: 0)
                    Text(snapshot.headline)
                        .font(Brand.font(20, weight: .heavy))
                        .minimumScaleFactor(0.7)
                    Text(snapshot.detail)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private var locked: some View {
        if family == .accessoryInline {
            Label("Sprout Pro", systemImage: "lock.fill")
        } else {
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
