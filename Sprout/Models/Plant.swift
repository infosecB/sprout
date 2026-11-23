import Foundation
import SwiftData

/// A houseplant and its care schedule.
///
/// Every property has a default and relationships are optional, so the model can sync through
/// CloudKit later without a migration. After release, only add properties (optional or with a default).
@Model
final class Plant {
    var id: UUID = UUID()
    var name: String = ""
    /// What kind of plant it is ("Monstera deliciosa"), free text.
    var species: String = ""
    /// Where it lives ("Living room"). Plants are grouped by it.
    var room: String = ""
    var notes: String = ""
    /// The SF Symbol drawn when there's no photo.
    var symbol: String = "leaf.fill"
    /// Index into `Brand.plantTints`.
    var tint: Int = 0
    @Attribute(.externalStorage) var photo: Data?
    /// Days between waterings.
    var waterEvery: Int = 7
    /// Days between feedings; 0 means no feeding schedule. Feeding reminders are Pro.
    var feedEvery: Int = 0
    var created: Date = Date.now
    @Relationship(deleteRule: .cascade, inverse: \CareEvent.plant) var events: [CareEvent]? = []

    init(name: String, species: String = "", room: String = "", symbol: String = "leaf.fill", tint: Int = 0,
         waterEvery: Int = 7, feedEvery: Int = 0, created: Date = .now) {
        self.name = name
        self.species = species
        self.room = room
        self.symbol = symbol
        self.tint = tint
        self.waterEvery = waterEvery
        self.feedEvery = feedEvery
        self.created = created
    }

    /// The care log, newest first.
    var history: [CareEvent] {
        (events ?? []).sorted { $0.date > $1.date }
    }

    /// When this kind of care was last logged.
    func last(_ kind: CareKind) -> Date? {
        (events ?? []).lazy.filter { $0.kind == kind }.map(\.date).max()
    }

    /// The days between `kind` of care, or nil if it has no schedule.
    func interval(_ kind: CareKind) -> Int? {
        switch kind {
        case .water: max(waterEvery, 1)
        case .feed: feedEvery > 0 ? feedEvery : nil
        default: nil
        }
    }

    /// The start of the day `kind` of care is next due, or nil if it has no schedule.
    func nextDue(_ kind: CareKind, calendar: Calendar = .current) -> Date? {
        guard let every = interval(kind) else { return nil }
        return CareSchedule.nextDue(last: last(kind), every: every, created: created, calendar: calendar)
    }

    /// The plant's photo, and every photo in its log, oldest first.
    var photos: [Data] {
        (events ?? []).sorted { $0.date < $1.date }.compactMap(\.photo)
    }
}

/// One entry in a plant's care log.
@Model
final class CareEvent {
    var id: UUID = UUID()
    var kindRaw: String = CareKind.water.rawValue
    var date: Date = Date.now
    var note: String = ""
    /// A progress photo. Pro.
    @Attribute(.externalStorage) var photo: Data?
    var plant: Plant?

    var kind: CareKind {
        get { CareKind(rawValue: kindRaw) ?? .note }
        set { kindRaw = newValue.rawValue }
    }

    init(kind: CareKind, date: Date = .now, note: String = "", photo: Data? = nil) {
        self.kindRaw = kind.rawValue
        self.date = date
        self.note = note
        self.photo = photo
    }
}
