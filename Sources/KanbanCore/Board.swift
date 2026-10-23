import CoreData
import Foundation

/// A Card as the Board shows it.
public struct Card: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let notes: String
    /// From 0 (neutral) to 1 (full red); always 0 in Done (ADR 0001).
    public let urgency: Double
    /// What the Card's age label shows: Card Age in Backlog, Column Age in Doing,
    /// `nil` in Done.
    public let age: TimeInterval?
}

/// How full Doing is: shown as "count / limit" in its header.
public struct WIPStatus: Equatable, Sendable {
    public let count: Int
    public let limit: Int

    public init(count: Int, limit: Int) {
        self.count = count
        self.limit = limit
    }

    /// Only after the limit was lowered below the Cards already in Doing.
    public var isOverLimit: Bool { count > limit }
}

/// Why the Board refused an operation.
public enum BoardError: LocalizedError, Equatable {
    case emptyTitle
    case cardNotFound
    case moveNotAllowed(from: Column, to: Column)
    case wipLimitReached(limit: Int)
    case wipLimitOutOfRange

    public var errorDescription: String? {
        switch self {
        case .emptyTitle: "A Card needs a title."
        case .cardNotFound: "That Card is no longer on the Board."
        case let .moveNotAllowed(from, to) where from == to: "The Card is already in \(to.title)."
        case .moveNotAllowed(from: .done, to: _): "Done Cards stay in Done."
        case .moveNotAllowed(from: _, to: .done): "Start a Card before finishing it: move it to Doing first."
        case let .moveNotAllowed(from, to): "Cards can't move from \(from.title) to \(to.title)."
        case let .wipLimitReached(limit): "Doing is at its WIP Limit of \(limit). Finish a Card before starting another."
        case .wipLimitOutOfRange: "The WIP Limit is between \(Board.wipLimits.lowerBound) and \(Board.wipLimits.upperBound)."
        }
    }
}

/// The single facade the app uses for the Board (spec 0001). All history is an
/// append-only event log (ADR 0002); everything else is computed from it.
@MainActor
public final class Board {
    private let container: NSPersistentContainer
    private var context: NSManagedObjectContext { container.viewContext }
    private let now: () -> Date
    /// The most Cards Doing may hold. Kept by the app, which passes it in (spec 0001).
    public private(set) var wipLimit: Int

    /// - Parameters:
    ///   - storeURL: the SQLite file, or `nil` for a store that lives only in memory.
    ///   - wipLimit: the stored WIP Limit; one outside `wipLimits` becomes the default.
    public init(storeURL: URL?, now: @escaping () -> Date = Date.init, wipLimit: Int = Board.defaultWIPLimit) throws {
        self.wipLimit = Self.wipLimits.contains(wipLimit) ? wipLimit : Self.defaultWIPLimit
        if let storeURL {
            try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        container = NSPersistentContainer(name: "MacKanban", managedObjectModel: StoreModel.shared)
        let description = NSPersistentStoreDescription(url: storeURL ?? URL(fileURLWithPath: "/dev/null"))
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }
        self.now = now
    }

    public func createCard(title: String, notes: String) throws {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw BoardError.emptyTitle }
        try change {
            let card = NSManagedObject(entity: StoreModel.shared.entitiesByName["Card"]!, insertInto: context)
            card.setValue(UUID(), forKey: "id")
            card.setValue(title, forKey: "title")
            card.setValue(notes.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "notes")
            try record(.created, for: card)
        }
    }

    public func move(_ id: UUID, to column: Column) throws {
        let card = try cardObject(id)
        let from = Self.column(of: card)
        guard Self.allowedMoves.contains([from, column]) else {
            throw BoardError.moveNotAllowed(from: from, to: column)
        }
        if column == .doing, try wipStatus().count >= wipLimit {
            throw BoardError.wipLimitReached(limit: wipLimit)
        }
        try change {
            let event = try record(.moved, for: card)
            event.setValue(from.rawValue, forKey: "fromColumn")
            event.setValue(column.rawValue, forKey: "toColumn")
        }
    }

    public func wipStatus() throws -> WIPStatus {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Card")
        request.relationshipKeyPathsForPrefetching = ["events"]
        let doing = try context.fetch(request).count { Self.column(of: $0) == .doing }
        return WIPStatus(count: doing, limit: wipLimit)
    }

    /// The WIP Limits the user can choose (ADR 0001: the only setting).
    public nonisolated static let wipLimits = 1...5
    public nonisolated static let defaultWIPLimit = 3

    /// Sets the WIP Limit and records a WIP Limit Changed Board Event. Cards
    /// already in Doing stay there, even above a lowered limit.
    public func changeWIPLimit(to limit: Int) throws {
        guard Self.wipLimits.contains(limit) else { throw BoardError.wipLimitOutOfRange }
        guard limit != wipLimit else { return }
        try change {
            let event = try record(.wipLimitChanged, for: nil)
            event.setValue(wipLimit, forKey: "fromNumber")
            event.setValue(limit, forKey: "toNumber")
        }
        wipLimit = limit
    }

    /// Forward through Doing, or from Doing back to Backlog. Nothing leaves Done.
    private static let allowedMoves: Set<[Column]> = [[.backlog, .doing], [.doing, .done], [.doing, .backlog]]

    @discardableResult
    private func record(_ kind: Event.Kind, for card: NSManagedObject?) throws -> NSManagedObject {
        let timestamp = try nextTimestamp()
        let event = NSManagedObject(entity: StoreModel.shared.entitiesByName["Event"]!, insertInto: context)
        event.setValue(kind.rawValue, forKey: "kind")
        event.setValue(timestamp, forKey: "timestamp")
        event.setValue(card, forKey: "card")
        return event
    }

    /// Now, or 1 ms after the latest event if the clock hasn't moved past it.
    /// The log has no sequence number (adding one would need a migration, ADR 0002),
    /// so strictly increasing timestamps are what keep its order unambiguous.
    private func nextTimestamp() throws -> Date {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1
        guard let latest = try context.fetch(request).first?.value(forKey: "timestamp") as? Date else { return now() }
        return max(now(), latest.addingTimeInterval(0.001))
    }

    private func cardObject(_ id: UUID) throws -> NSManagedObject {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Card")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        guard let card = try context.fetch(request).first else { throw BoardError.cardNotFound }
        return card
    }

    /// Makes `changes` and saves them, or drops all of them if any step fails,
    /// so the Board never shows or later saves half an operation.
    private func change(_ changes: () throws -> Void) throws {
        do {
            try changes()
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    /// The Cards in `column`, in its display order (see `columns()`).
    public func cards(in column: Column) throws -> [Card] {
        try columns()[column] ?? []
    }

    /// Every Column's Cards in display order: Backlog oldest first, Doing longest
    /// in Doing first (counting every visit), Done most recently finished first.
    public func columns() throws -> [Column: [Card]] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Card")
        request.relationshipKeyPathsForPrefetching = ["events"]
        let now = now()
        let placed = try context.fetch(request).map { object in
            let visits = Self.visits(of: object)
            let column = visits.last?.column ?? .backlog
            let created = visits.first?.entered ?? now
            let timeInDoing = visits.timeSpent(in: .doing, until: now)
            // The age the Card's label shows, and the ascending sort key for its Column.
            let (age, key): (TimeInterval?, TimeInterval) = switch column {
            case .backlog: (max(0, now.timeIntervalSince(created)), created.timeIntervalSinceReferenceDate)
            case .doing: (timeInDoing, -timeInDoing)
            case .done: (nil, -(visits.last?.entered ?? now).timeIntervalSinceReferenceDate)
            }
            return (object: object, column: column, key: key, age: age)
        }
        return Dictionary(grouping: placed, by: \.column).mapValues { cards in
            cards.sorted { $0.key < $1.key }.compactMap { Self.card($0.object, in: $0.column, age: $0.age) }
        }
    }

    /// The whole event log, oldest first.
    public func events() throws -> [Event] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Event")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        return try context.fetch(request).compactMap { object in
            guard let kind = (object.value(forKey: "kind") as? String).flatMap(Event.Kind.init),
                  let timestamp = object.value(forKey: "timestamp") as? Date
            else { return nil }
            let card = object.value(forKey: "card") as? NSManagedObject
            return Event(kind: kind, timestamp: timestamp, cardID: card?.value(forKey: "id") as? UUID,
                         from: (object.value(forKey: "fromColumn") as? String).flatMap(Column.init),
                         to: (object.value(forKey: "toColumn") as? String).flatMap(Column.init),
                         fromNumber: (object.value(forKey: "fromNumber") as? NSNumber)?.intValue,
                         toNumber: (object.value(forKey: "toNumber") as? NSNumber)?.intValue)
        }
    }

    /// The Card's events in the order they happened.
    private static func history(of card: NSManagedObject) -> [NSManagedObject] {
        let events = card.value(forKey: "events") as? Set<NSManagedObject> ?? []
        return events.sorted {
            ($0.value(forKey: "timestamp") as? Date ?? .distantPast) < ($1.value(forKey: "timestamp") as? Date ?? .distantPast)
        }
    }

    /// Where the Card is now: the Column its latest move went to, else Backlog.
    private static func column(of card: NSManagedObject) -> Column {
        visits(of: card).last?.column ?? .backlog
    }

    /// The Card's Column Visits, replayed from its Created and Moved events.
    private static func visits(of card: NSManagedObject) -> [ColumnVisit] {
        var visits: [ColumnVisit] = []
        for event in history(of: card) {
            guard let time = event.value(forKey: "timestamp") as? Date else { continue }
            switch (event.value(forKey: "kind") as? String).flatMap(Event.Kind.init) {
            case .created:
                visits.append(ColumnVisit(column: .backlog, entered: time))
            case .moved:
                guard let to = (event.value(forKey: "toColumn") as? String).flatMap(Column.init) else { continue }
                if !visits.isEmpty { visits[visits.count - 1].left = time }
                visits.append(ColumnVisit(column: to, entered: time))
            case .wipLimitChanged, nil:
                continue
            }
        }
        return visits
    }

    /// `nil` for a row without an ID, which only a damaged or half-synced store has.
    private static func card(_ object: NSManagedObject, in column: Column, age: TimeInterval?) -> Card? {
        guard let id = object.value(forKey: "id") as? UUID else { return nil }
        return Card(id: id,
                    title: object.value(forKey: "title") as? String ?? "",
                    notes: object.value(forKey: "notes") as? String ?? "",
                    urgency: age.map { Urgency.of(age: $0, in: column) } ?? 0,
                    age: age)
    }
}
