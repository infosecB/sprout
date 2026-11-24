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
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Brand.leaf)
            Text("Welcome to Sprout")
                .font(Brand.font(28))
            Text("Add your plants and how often they like water. Sprout reminds you when each one is thirsty and keeps a log of everything you do for it.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            Button {
                adding = true
            } label: {
                Label("Add your first plant", systemImage: "plus")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: 320, minHeight: 50)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: Brand.radius))
            .tint(Brand.accent)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func summary(due: [CareTask], next: CareTask?) -> some View {
        let count = Set(due.map(\.plant.id)).count
        return VStack(alignment: .leading, spacing: 6) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.accent)
            Text(count == 0 ? "All caught up." : count == 1 ? "One plant needs you." : "\(count) plants need you.")
                .font(Brand.font(30, weight: .medium))
            if count == 0, let next {
                Text("Next up: \(next.plant.name), \(CareSchedule.describe(next.due).lowercased()).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func dueSection(_ due: [CareTask]) -> some View {
        if !due.isEmpty {
            VStack(spacing: 8) {
                SectionTitle(title: "Needs care", trailing: due.count > 1 ? AnyView(
                    Button("Do all") { log(due) }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.accent)
                ) : nil)
                taskList(due, upcoming: false)
            }
        }
    }

    @ViewBuilder private func soonSection(_ soon: [CareTask]) -> some View {
        if !soon.isEmpty {
            VStack(spacing: 8) {
                SectionTitle(title: "This week")
                taskList(soon, upcoming: true)
            }
        }
    }

    /// Tasks as rows in one card, split by hairlines.
    private func taskList(_ tasks: [CareTask], upcoming: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(tasks) { task in
                TaskRow(task: task, upcoming: upcoming) { log([task]) }
                if task.id != tasks.last?.id { RowDivider(inset: 76) }
            }
        }
        .card(padding: 0)
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
        let late = CareSchedule.days(until: task.due) < 0
        HStack(spacing: 14) {
            NavigationLink(value: task.plant) {
                HStack(spacing: 14) {
                    PlantAvatar(plant: task.plant, size: 46)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.plant.name)
                            .font(Brand.font(18))
                            .foregroundStyle(.primary)
                        HStack(spacing: 4) {
                            Text(task.kind.needs)
                            Text("·")
                            Text(CareSchedule.describe(task.due))
                                .foregroundStyle(late ? Brand.accent : .secondary)
                                .fontWeight(late ? .semibold : .regular)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            CareButton(kind: task.kind, size: 40, quiet: upcoming, action: action)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    TodayView(showPaywall: .constant(false))
        .environment(Store())
        .modelContainer(PlantStore.container)
}
