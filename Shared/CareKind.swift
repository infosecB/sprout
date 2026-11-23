import SwiftUI

/// The kinds of care Sprout logs. Water and feed have schedules; the rest are one-off log entries.
///
/// The raw values are saved in the store and the widget snapshot, so never rename them.
enum CareKind: String, CaseIterable, Codable, Identifiable {
    case water, feed, mist, repot, prune, note

    var id: Self { self }

    /// Kinds that can have a repeating schedule.
    static let scheduled: [CareKind] = [.water, .feed]

    var label: String {
        switch self {
        case .water: "Water"
        case .feed: "Feed"
        case .mist: "Mist"
        case .repot: "Repot"
        case .prune: "Prune"
        case .note: "Note"
        }
    }

    /// How a log entry reads: "Watered", "Fed".
    var done: String {
        switch self {
        case .water: "Watered"
        case .feed: "Fed"
        case .mist: "Misted"
        case .repot: "Repotted"
        case .prune: "Pruned"
        case .note: "Note"
        }
    }

    /// What a due task asks for: "Needs water".
    var needs: String {
        switch self {
        case .water: "Needs water"
        case .feed: "Needs feeding"
        default: label
        }
    }

    var symbol: String {
        switch self {
        case .water: "drop.fill"
        case .feed: "flask.fill"
        case .mist: "humidity.fill"
        case .repot: "archivebox.fill"
        case .prune: "scissors"
        case .note: "note.text"
        }
    }

    var color: Color {
        switch self {
        case .water: Brand.water
        case .feed: Brand.feed
        case .mist: Brand.water.opacity(0.75)
        case .repot: Brand.accent
        case .prune: Brand.leaf
        case .note: .secondary
        }
    }
}
