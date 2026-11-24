import SwiftData
import SwiftUI

/// One plant: its schedule, quick care buttons, photos and care log.
struct PlantDetailView: View {
    @Environment(Store.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: Plant
    @Binding var showPaywall: Bool

    @State private var editing = false
    @State private var logging: CareKind?

    var body: some View {
        GeometryReader { proxy in
            let margin = Brand.margin(for: proxy.size)
            ScrollView {
                Group {
                    if Brand.isWide(proxy.size) {
                        HStack(alignment: .top, spacing: 20) {
                            VStack(spacing: 18) { header; schedule; actions }
                                .frame(maxWidth: .infinity)
                            VStack(spacing: 18) { photoStrip; log }
                                .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: 1000)
                    } else {
                        VStack(spacing: 18) { header; schedule; actions; photoStrip; log }
                            .frame(maxWidth: 640)
                    }
                }
                .padding(margin)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Brand.background)
            .navigationTitle(plant.name)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                Button("Edit") { editing = true }
            }
            .sheet(isPresented: $editing) {
                PlantEditor(plant: plant) { dismiss() }
            }
            .sheet(item: $logging) { kind in
                LogCareSheet(plant: plant, kind: kind)
            }
        }
    }

    // MARK: Parts

    private var header: some View {
        VStack(spacing: 10) {
            PlantAvatar(plant: plant, size: 104)
            Text(plant.name).font(Brand.font(32, weight: .medium)).multilineTextAlignment(.center)
            if !plant.species.isEmpty {
                Text(plant.species).font(Brand.font(17, weight: .regular)).italic().foregroundStyle(.secondary)
            }
            if !plant.room.isEmpty {
                Label(plant.room, systemImage: "house").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            if !plant.notes.isEmpty {
                Text(plant.notes)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var schedule: some View {
        VStack(spacing: 0) {
            scheduleRow(.water, every: plant.waterEvery)
            RowDivider(inset: 46)
            if store.isPro {
                if plant.feedEvery > 0 {
                    scheduleRow(.feed, every: plant.feedEvery)
                } else {
                    Button { editing = true } label: {
                        rowLabel(.feed, title: "No feeding schedule", detail: "Tap to add one")
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button { showPaywall = true } label: {
                    HStack {
                        rowLabel(.feed, title: "Feeding reminders", detail: "Fertilise on a schedule")
                        ProBadge()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .card(padding: 14)
    }

    private func scheduleRow(_ kind: CareKind, every: Int) -> some View {
        let due = plant.nextDue(kind)
        let last = plant.last(kind)
        return HStack {
            rowLabel(kind, title: "\(kind.label) every \(every) \(every == 1 ? "day" : "days")",
                     detail: last.map { "\(kind.done) \(CareSchedule.ago($0))" } ?? "Not logged yet")
            if let due {
                Text(CareSchedule.describe(due))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CareSchedule.days(until: due) <= 0 ? Brand.accent : .secondary)
            }
        }
    }

    private func rowLabel(_ kind: CareKind, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: kind.symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(kind.color)
                .frame(width: 34, height: 34)
                .background(kind.color.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "Log care")
            HStack(spacing: 0) {
                ForEach(CareKind.allCases) { kind in
                    VStack(spacing: 6) {
                        CareButton(kind: kind, size: 44) { tapped(kind) }
                        Text(kind.label).font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .card(padding: 14)
        }
    }

    /// Water, feed and mist log straight away; the rest want a note.
    private func tapped(_ kind: CareKind) {
        switch kind {
        case .water, .feed, .mist:
            CareLog.log(kind, for: plant, in: context)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        default:
            logging = kind
        }
    }

    @ViewBuilder private var photoStrip: some View {
        let photos = plant.photos
        if store.isPro && !photos.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle(title: "Growth")
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(Array(photos.enumerated()), id: \.offset) { _, data in
                            if let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 140)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var log: some View {
        let visible = FreeLimits.visibleHistory(plant.history, isPro: store.isPro)
        return VStack(alignment: .leading, spacing: 8) {
            SectionTitle(title: "History", trailing: AnyView(
                Button("Add entry") { logging = .note }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.accent)
            ))
            historyRows(visible)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func historyRows(_ visible: (shown: [CareEvent], hidden: Int)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if visible.shown.isEmpty && visible.hidden == 0 {
                Text("Nothing logged yet. Tap a button above when you care for \(plant.name).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(visible.shown) { event in
                EventRow(event: event)
                    .contextMenu {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            CareLog.remove(event, in: context)
                        }
                    }
                if event.id != visible.shown.last?.id { RowDivider(inset: 40) }
            }
            if visible.hidden > 0 {
                Button { showPaywall = true } label: {
                    HStack {
                        Image(systemName: "lock.fill")
                        Text("\(visible.hidden) older \(visible.hidden == 1 ? "entry" : "entries")")
                        Spacer()
                        Text("Full history")
                        ProBadge()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

private struct EventRow: View {
    let event: CareEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: event.kind.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(event.kind.color)
                .frame(width: 28, height: 28)
                .background(event.kind.color.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(event.kind.done).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(event.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !event.note.isEmpty {
                    Text(event.note).font(.subheadline).foregroundStyle(.secondary)
                }
                if let data = event.photo, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 220, maxHeight: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
