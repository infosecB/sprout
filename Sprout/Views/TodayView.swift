import SwiftData
import SwiftUI

/// The first tab: what needs care today, one tap to log it, and what's coming up this week.
struct TodayView: View {
    @Environment(Store.self) private var store
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Plant.name) private var plants: [Plant]
    @Binding var showPaywall: Bool

    @State private var adding = false
    @State private var lastLogged: [CareEvent] = []
    @State private var undoText = ""

    var body: some View {
        GeometryReader { proxy in
            let margin = Brand.margin(for: proxy.size)
            let tasks = CareSchedule.tasks(for: plants, includeFeeding: store.isPro)
            let due = tasks.filter { CareSchedule.isDue($0) }
            let soon = tasks.filter { !CareSchedule.isDue($0) && CareSchedule.days(until: $0.due) <= 7 }
            NavigationStack {
                ScrollView {
                    VStack(spacing: 22) {
                        if plants.isEmpty {
                            empty
                        } else {
                            summary(due: due, next: tasks.first { !CareSchedule.isDue($0) })
                            if Brand.isWide(proxy.size) {
                                HStack(alignment: .top, spacing: 20) {
                                    dueSection(due).frame(maxWidth: .infinity)
                                    soonSection(soon).frame(maxWidth: .infinity)
                                }
                            } else {
                                dueSection(due)
                                soonSection(soon)
                            }
                        }
                    }
                    .frame(maxWidth: Brand.isWide(proxy.size) ? 1000 : 640)
                    .padding(margin)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
                .background(Brand.background)
                .navigationTitle("Today")
                .navigationDestination(for: Plant.self) { PlantDetailView(plant: $0, showPaywall: $showPaywall) }
                .sheet(isPresented: $adding) { PlantEditor(plant: nil) }
                .overlay(alignment: .bottom) {
                    if !lastLogged.isEmpty {
                        UndoBanner(text: undoText) { undo() }
                    }
                }
            }
        }
    }

    // MARK: Sections

    private var empty: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.macro")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(Brand.leaf)
            Text("Welcome to Sprout")
                .font(Brand.font(28, weight: .heavy))
            Text("Add your plants and how often they like water. Sprout reminds you when each one is thirsty and keeps a log of everything you do for it.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                adding = true
            } label: {
                Label("Add your first plant", systemImage: "plus")
                    .font(Brand.font(18))
                    .frame(maxWidth: 320, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(Brand.accent)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 28)
        .padding(.top, 20)
    }

    private func summary(due: [CareTask], next: CareTask?) -> some View {
        let count = Set(due.map(\.plant.id)).count
        return HStack(spacing: 18) {
            ZStack {
                Circle().fill((count == 0 ? Brand.leaf : Brand.water).opacity(0.15))
                Image(systemName: count == 0 ? "checkmark" : "drop.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(count == 0 ? Brand.leaf : Brand.water)
            }
            .frame(width: 68, height: 68)
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()).uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(count == 0 ? "All caught up" : count == 1 ? "1 plant needs you" : "\(count) plants need you")
                    .font(Brand.font(24, weight: .heavy))
                if count == 0, let next {
                    Text("Next: \(next.plant.name), \(CareSchedule.describe(next.due).lowercased())")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func dueSection(_ due: [CareTask]) -> some View {
        if !due.isEmpty {
            VStack(spacing: 10) {
                SectionTitle(title: "Needs care", trailing: due.count > 1 ? AnyView(
                    Button("Do all") { log(due) }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Brand.accent)
                ) : nil)
                ForEach(due) { task in
                    TaskRow(task: task) { log([task]) }
                }
            }
        }
    }

    @ViewBuilder private func soonSection(_ soon: [CareTask]) -> some View {
        if !soon.isEmpty {
            VStack(spacing: 10) {
                SectionTitle(title: "This week")
                ForEach(soon) { task in
                    TaskRow(task: task, upcoming: true) { log([task]) }
                }
            }
        }
    }

    // MARK: Logging

    private func log(_ tasks: [CareTask]) {
        let events = tasks.map { CareLog.log($0.kind, for: $0.plant, in: context) }
        undoText = tasks.count == 1
            ? "\(tasks[0].kind.done) \(tasks[0].plant.name)"
            : "Logged care for \(Set(tasks.map(\.plant.id)).count) plants"
        withAnimation(reduceMotion ? nil : .spring(duration: 0.35)) { lastLogged = events }
        let logged = events
        Task {
            try? await Task.sleep(for: .seconds(4))
            if lastLogged == logged {
                withAnimation(reduceMotion ? nil : .easeOut) { lastLogged = [] }
            }
        }
    }

    private func undo() {
        for event in lastLogged { CareLog.remove(event, in: context) }
        withAnimation(reduceMotion ? nil : .easeOut) { lastLogged = [] }
    }
}

/// A plant, what it needs and when, and a button to log it.
private struct TaskRow: View {
    let task: CareTask
    var upcoming = false
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            NavigationLink(value: task.plant) {
                HStack(spacing: 14) {
                    PlantAvatar(plant: task.plant, size: 50)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(task.plant.name)
                            .font(Brand.font(17))
                            .foregroundStyle(.primary)
                        HStack(spacing: 5) {
                            Image(systemName: task.kind.symbol).foregroundStyle(task.kind.color)
                            Text("\(task.kind.needs) · \(CareSchedule.describe(task.due))")
                                .foregroundStyle(CareSchedule.days(until: task.due) < 0 ? Brand.accent : .secondary)
                        }
                        .font(.subheadline.weight(.medium))
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            CareButton(kind: task.kind, size: upcoming ? 38 : 46, action: action)
                .opacity(upcoming ? 0.55 : 1)
        }
        .card(padding: 14)
    }
}

#Preview {
    TodayView(showPaywall: .constant(false))
        .environment(Store())
        .modelContainer(PlantStore.container)
}
