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

/// What the Board window shows, computed together at one moment.
public struct BoardState: Sendable {
    public let columns: [Column: [Card]]
    public let capacity: Capacity
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
    case cardIsDone
    case sampleCardIsReadOnly
    case sampleCardsNeedEmptyBoard
    case cannotUndo
    case cardExists
    case creationBlocked(capacity: Int, openCards: Int, cardsToFree: Int)

    public var errorDescription: String? {
        switch self {
        case .emptyTitle: "A Card needs a title."
        case .cardNotFound: "That Card is no longer on the Board."
        case let .moveNotAllowed(from, to) where from == to: "The Card is already in \(to.title)."
        case .moveNotAllowed(from: .done, to: _): "Done Cards stay in Done."
        case .moveNotAllowed(from: _, to: .done): "Start a Card before finishing it: move it to Doing first."
        case let .moveNotAllowed(from, to): "Cards can't move from \(from.title) to \(to.title)."
        case let .wipLimitReached(limit): "Doing is at its WIP Limit of \(limit). Finish a Card before starting another."
        case .cardIsDone: "Done Cards stay as they were finished."
        case .sampleCardIsReadOnly: "Sample Cards can't be edited. Create your own Card instead."
        case .sampleCardsNeedEmptyBoard: "Sample Cards can only be added while the Board has no Open Cards and no Sample Cards."
        case .cardExists: "A Card with this ID already exists."
        case let .creationBlocked(capacity, openCards, cardsToFree):
            "Capacity \(capacity), Open Cards \(openCards): finish or Discard \(cardsToFree) "
                + (cardsToFree == 1 ? "Card." : "Cards.")
        case .cannotUndo: "This can't be undone any more: the Card has changed since."
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

    /// - Parameter id: a new Card gets a new ID; redoing an undone creation passes
    ///   the old one, so later redos (a move, a Discard) still find the Card.
    @discardableResult
    public func createCard(title: String, notes: String, id: UUID = UUID()) throws -> Change {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw BoardError.emptyTitle }
        if case let .blocked(capacity, openCards, cardsToFree) = try creationGate() {
            throw BoardError.creationBlocked(capacity: capacity, openCards: openCards, cardsToFree: cardsToFree)
        }
        guard try context.count(for: Self.cardRequest(id)) == 0 else { throw BoardError.cardExists }
        let event = try change {
            try record(.created, for: insertCard(id: id, title: title, notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        return Change(cardID: id, isCreation: true, event: event.objectID.uriRepresentation())
    }

    private func insertCard(id: UUID, title: String, notes: String) -> NSManagedObject {
        let card = NSManagedObject(entity: StoreModel.shared.entitiesByName["Card"]!, insertInto: context)
        card.setValue(id, forKey: "id")
        card.setValue(title, forKey: "title")
        card.setValue(notes, forKey: "notes")
        return card
    }

    @discardableResult
    public func move(_ id: UUID, to column: Column) throws -> Change {
        let (card, from) = try cardOnBoard(id)
        if let refusal = try moveRefusal(from: from, to: column) { throw refusal }
        let event = try change { try recordMove(of: card, from: from, to: column) }
        return Change(cardID: id, isCreation: false, event: event.objectID.uriRepresentation())
    }

    @discardableResult
    private func recordMove(of card: NSManagedObject, from: Column, to column: Column) throws -> NSManagedObject {
        recordMove(of: card, from: from, to: column, at: try nextTimestamp())
    }

    @discardableResult
    private func recordMove(of card: NSManagedObject, from: Column, to column: Column, at timestamp: Date) -> NSManagedObject {
        let event = record(.moved, for: card, at: timestamp)
        event.setValue(from.rawValue, forKey: "fromColumn")
        event.setValue(column.rawValue, forKey: "toColumn")
        return event
    }

    /// Why moving the Card to `column` would be refused, or `nil` if it's allowed:
    /// lets the app show it while a Card is dragged, before anything is moved.
    public func moveRefusal(_ id: UUID, to column: Column) throws -> BoardError? {
        try moveRefusal(from: cardOnBoard(id).column, to: column)
    }

    private func moveRefusal(from: Column, to column: Column) throws -> BoardError? {
        guard Self.allowedMoves.contains([from, column]) else { return .moveNotAllowed(from: from, to: column) }
        if column == .doing, try wipStatus().count >= wipLimit { return .wipLimitReached(limit: wipLimit) }
        return nil
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

    /// Changes the Card's title and notes. The Edited event records only that it
    /// happened, never the text.
    public func edit(_ id: UUID, title: String, notes: String) throws {
        let (card, column) = try cardOnBoard(id)
        guard column != .done else { throw BoardError.cardIsDone }
        guard !SampleCards.isSample(id) else { throw BoardError.sampleCardIsReadOnly }
        let (title, notes) = (title.trimmingCharacters(in: .whitespacesAndNewlines),
                              notes.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !title.isEmpty else { throw BoardError.emptyTitle }
        guard title != card.value(forKey: "title") as? String ?? "" || notes != card.value(forKey: "notes") as? String ?? "" else { return }
        try change {
            card.setValue(title, forKey: "title")
            card.setValue(notes, forKey: "notes")
            try record(.edited, for: card)
        }
    }

    /// Takes an Open Card off the Board for good. It stays in the event log, but
    /// it isn't a completion: it never counts as Throughput (ADR 0001).
    @discardableResult
    public func discard(_ id: UUID) throws -> Change {
        let (card, column) = try cardOnBoard(id)
        guard column != .done else { throw BoardError.cardIsDone }
        let event = try change { try record(.discarded, for: card) }
        return Change(cardID: id, isCreation: false, event: event.objectID.uriRepresentation())
    }

    /// How long a Card stays in Done before it leaves the Board for the Archive.
    /// Never recorded: it follows from the Moved-to-Done event (ADR 0002).
    public nonisolated static let archiveDelay: TimeInterval = 7 * 86_400

    /// How long after an operation it can still be undone. Undo is for slips
    /// straight after they happen, not for rewriting history (ADR 0002).
    public nonisolated static let undoWindow: TimeInterval = 15 * 60

    /// Undoes `change` by deleting the event it recorded, so the slip never shows up
    /// in the history (ADR 0002). Refused once the Card has moved on since (its
    /// Column history has a newer event; Edited and Triaged events don't count), after
    /// `undoWindow`, or when it would put Doing over the WIP Limit.
    public func revert(_ change: Change) throws {
        let card = try anyCard(change.cardID)
        let history = Self.history(of: card)
        let placing = history.filter {
            [Event.Kind.created, .moved, .discarded].map(\.rawValue).contains($0.value(forKey: "kind") as? String)
        }
        guard let event = placing.last, event.objectID.uriRepresentation() == change.event,
              !change.isCreation || placing.count == 1,
              let time = event.value(forKey: "timestamp") as? Date, now().timeIntervalSince(time) <= Self.undoWindow
        else { throw BoardError.cannotUndo }

        let companions = history.filter { change.companions.contains($0.objectID.uriRepresentation()) }
        let restored = Self.column(after: Self.visits(of: history.filter { $0 != event }))
        if restored == .doing, Self.column(of: card) != .doing, try wipStatus().count >= wipLimit {
            throw BoardError.wipLimitReached(limit: wipLimit)
        }
        try self.change {
            if change.isCreation {
                context.delete(card)  // a Card's events go with it
            } else {
                for event in [event] + companions { context.delete(event) }
            }
        }
    }

    /// Adds the Sample Cards with their histories written into the past, so they
    /// have their ages the moment they appear (ADR 0005). Only while the Board has
    /// no Open Cards and no Sample Cards, so their Capacity is known: a Doing chore
    /// that would go over the WIP Limit stays in Backlog.
    public func addSampleCards() throws {
        guard try canAddSampleCards() else { throw BoardError.sampleCardsNeedEmptyBoard }
        let now = now()
        func ago(_ days: Double) -> Date { now.addingTimeInterval(-days * 86_400) }
        var doing = 0
        try change {
            for chore in SampleCards.chores {
                let card = insertCard(id: chore.id, title: chore.title, notes: chore.notes)
                record(.created, for: card, at: ago(chore.created))
                guard let started = chore.started else {
                    if let discarded = chore.discarded { record(.discarded, for: card, at: ago(discarded)) }
                    continue
                }
                if chore.finished == nil {
                    guard doing < wipLimit else { continue }
                    doing += 1
                }
                recordMove(of: card, from: .backlog, to: .doing, at: ago(started))
                if let finished = chore.finished { recordMove(of: card, from: .doing, to: .done, at: ago(finished)) }
            }
        }
    }

    /// Takes every Sample Card off the Board, Archive included, together with its
    /// Card Events, leaving no trace (ADR 0005). Board Events stay. Returns how
    /// many were removed.
    @discardableResult
    public func removeSampleCards() throws -> Int {
        let samples = try sampleCards()
        try change {
            for card in samples { context.delete(card) }  // a Card's events go with it
        }
        return samples.count
    }

    /// Sample Cards anywhere: on the Board, in the Archive or Discarded.
    public func sampleCardCount() throws -> Int {
        try sampleCards().count
    }

    /// Whether `addSampleCards()` is allowed: no Open Cards and no Sample Cards.
    public func canAddSampleCards() throws -> Bool {
        try sampleCardCount() == 0 && state().capacity.openCards == 0
    }

    /// Whether any Card was ever created and is still stored, wherever it is now:
    /// the first-launch offer of Sample Cards is only for a Board without any.
    public func hasCards() throws -> Bool {
        try context.count(for: NSFetchRequest<NSManagedObject>(entityName: "Card")) > 0
    }

    private func sampleCards() throws -> [NSManagedObject] {
        try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Card")).filter {
            ($0.value(forKey: "id") as? UUID).map(SampleCards.isSample) ?? false
        }
    }

    /// Forward through Doing, or from Doing back to Backlog. Nothing leaves Done.
    private static let allowedMoves: Set<[Column]> = [[.backlog, .doing], [.doing, .done], [.doing, .backlog]]

    /// The Columns a Card in `column` may move to, forward first: what a Card's
    /// context menu offers. Whether a move goes through still depends on the
    /// WIP Limit, so `move` can refuse one of these.
    public static func moveTargets(from column: Column) -> [Column] {
        Column.allCases.reversed().filter { allowedMoves.contains([column, $0]) }
    }

    @discardableResult
    private func record(_ kind: Event.Kind, for card: NSManagedObject?) throws -> NSManagedObject {
        record(kind, for: card, at: try nextTimestamp())
    }

    /// Only Sample Cards are written at a given time, into the past (ADR 0005).
    @discardableResult
    private func record(_ kind: Event.Kind, for card: NSManagedObject?, at timestamp: Date) -> NSManagedObject {
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

    /// The Card, on the Board or Discarded.
    private func anyCard(_ id: UUID) throws -> NSManagedObject {
        guard let card = try context.fetch(Self.cardRequest(id)).first else { throw BoardError.cardNotFound }
        return card
    }

    private static func cardRequest(_ id: UUID) -> NSFetchRequest<NSManagedObject> {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Card")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return request
    }

    /// The Card and its Column, if it's on the Board: Discarded Cards aren't.
    private func cardOnBoard(_ id: UUID) throws -> (card: NSManagedObject, column: Column) {
        let card = try anyCard(id)
        guard let column = Self.column(of: card) else { throw BoardError.cardNotFound }
        return (card, column)
    }

    /// Makes `changes` and saves them, or drops all of them if any step fails,
    /// so the Board never shows or later saves half an operation.
    private func change<Result>(_ changes: () throws -> Result) throws -> Result {
        do {
            let result = try changes()
            try context.save()
            return result
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
        try state().columns
    }

    public func capacity() throws -> Capacity {
        try state().capacity
    }

    /// The Columns and Capacity from one pass over the Cards, at one moment: what
    /// the Board window shows on every refresh.
    public func state() throws -> BoardState {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Card")
        request.relationshipKeyPathsForPrefetching = ["events"]
        let now = now()
        let throughputSince = now.addingTimeInterval(-Capacity.throughputWindow)
        var throughput = 0
        let placed = try context.fetch(request).compactMap { object -> (card: Card, column: Column, key: TimeInterval)? in
            let visits = Self.visits(of: object)
            // From the history, not from what's on the Board: archived Done Cards
            // still count, and Discarded Cards never entered Done.
            if visits.contains(where: { $0.column == .done && $0.entered >= throughputSince }) { throughput += 1 }
            guard let column = Self.column(after: visits) else { return nil }  // Discarded
            if Self.isArchived(visits, at: now) { return nil }
            let created = visits.first?.entered ?? now
            let timeInDoing = visits.timeSpent(in: .doing, until: now)
            // The age the Card's label shows, and the ascending sort key for its Column.
            let (age, key): (TimeInterval?, TimeInterval) = switch column {
            case .backlog: (max(0, now.timeIntervalSince(created)), created.timeIntervalSinceReferenceDate)
            case .doing: (timeInDoing, -timeInDoing)
            case .done: (nil, -(visits.last?.entered ?? now).timeIntervalSinceReferenceDate)
            }
            guard let card = Self.card(object, in: column, age: age) else { return nil }
            return (card, column, key)
        }
        let columns = Dictionary(grouping: placed, by: \.column).mapValues { cards in
            cards.sorted { $0.key < $1.key }.map(\.card)
        }
        let open = (columns[.backlog] ?? []) + (columns[.doing] ?? [])
        let capacity = Capacity(throughput: throughput, aging: open.reduce(0) { $0 + $1.urgency }, openCards: open.count)
        return BoardState(columns: columns, capacity: capacity)
    }

    /// Whether creating a Card goes straight ahead or needs a Triage first.
    public func creationGate() throws -> CreationGate {
        let state = try state()
        let open = (state.columns[.backlog] ?? []) + (state.columns[.doing] ?? [])
        let capacity = state.capacity
        guard capacity.free > 0 else {
            // Discarding the most urgent first frees a slot soonest; finishing a Card
            // also adds Throughput, so this many is always enough.
            var removed = 0
            var aging = capacity.aging
            for urgency in open.map(\.urgency).sorted(by: >) {
                removed += 1
                aging -= urgency
                if Capacity(throughput: capacity.throughput, aging: aging, openCards: capacity.openCards - removed).free > 0 { break }
            }
            return .blocked(capacity: capacity.total, openCards: capacity.openCards, cardsToFree: removed)
        }
        // On a tie, the first in display order: Backlog's oldest before Doing.
        let mostUrgent = open.reduce(nil as Card?) { best, card in
            card.urgency > best?.urgency ?? -1 ? card : best
        }
        guard let mostUrgent, state.capacity.free <= CreationGate.triageThreshold || mostUrgent.urgency >= 1
        else { return .open }
        return .triage(mostUrgent)
    }

    /// Records the outcome of a Triage of the Card, after starting or Discarding
    /// it for those outcomes. Only those two can be undone: they return the Change.
    @discardableResult
    public func triage(_ id: UUID, outcome: TriageOutcome) throws -> Change? {
        let (card, column) = try cardOnBoard(id)
        guard column != .done else { throw BoardError.cardIsDone }  // only Open Cards are triaged
        if outcome == .started, let refusal = try moveRefusal(from: column, to: .doing) { throw refusal }
        let (placing, triaged) = try change {
            let placing: NSManagedObject? = switch outcome {
            case .started: try recordMove(of: card, from: column, to: .doing)
            case .discarded: try record(.discarded, for: card)
            case .kept, .dismissed: nil
            }
            let triaged = try record(.triaged, for: card)
            triaged.setValue(outcome.rawValue, forKey: "triageOutcome")
            return (placing, triaged)
        }
        guard let placing else { return nil }
        return Change(cardID: id, isCreation: false, event: placing.objectID.uriRepresentation(),
                      companions: [triaged.objectID.uriRepresentation()])
    }

    /// What the New Card button calls: the gate, and when it's blocked, a Creation
    /// Blocked Board Event for this attempt.
    @discardableResult
    public func attemptCreation() throws -> CreationGate {
        let gate = try creationGate()
        if case let .blocked(capacity, openCards, _) = gate {
            try change {
                let event = try record(.creationBlocked, for: nil)
                event.setValue(capacity, forKey: "capacity")
                event.setValue(openCards, forKey: "openCardCount")
            }
        }
        return gate
    }

    /// Archived Done Cards and Discarded Cards, the most recently ended first.
    public func archive() throws -> [ArchivedCard] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Card")
        request.relationshipKeyPathsForPrefetching = ["events"]
        let now = now()
        return try context.fetch(request).compactMap { object -> ArchivedCard? in
            let visits = Self.visits(of: object)
            guard let created = visits.first?.entered, let last = visits.last,
                  let card = Self.card(object, in: .done, age: nil)  // read-only, no Urgency
            else { return nil }
            if let discarded = last.left {
                return ArchivedCard(card: card, created: created, ended: discarded, outcome: .discarded)
            }
            guard Self.isArchived(visits, at: now) else { return nil }
            return ArchivedCard(card: card, created: created, ended: last.entered, outcome: .done)
        }
        .sorted { $0.ended > $1.ended }
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
                         toNumber: (object.value(forKey: "toNumber") as? NSNumber)?.intValue,
                         triageOutcome: (object.value(forKey: "triageOutcome") as? String).flatMap(TriageOutcome.init),
                         capacity: (object.value(forKey: "capacity") as? NSNumber)?.intValue,
                         openCards: (object.value(forKey: "openCardCount") as? NSNumber)?.intValue)
        }
    }

    /// The Card's events in the order they happened.
    private static func history(of card: NSManagedObject) -> [NSManagedObject] {
        let events = card.value(forKey: "events") as? Set<NSManagedObject> ?? []
        return events.sorted {
            ($0.value(forKey: "timestamp") as? Date ?? .distantPast) < ($1.value(forKey: "timestamp") as? Date ?? .distantPast)
        }
    }

    /// Whether the Card is a Done Card that has left the Board for the Archive:
    /// `archiveDelay` after entering Done, never recorded (ADR 0002).
    private static func isArchived(_ visits: [ColumnVisit], at now: Date) -> Bool {
        guard let last = visits.last, last.column == .done, last.left == nil else { return false }
        return now.timeIntervalSince(last.entered) >= archiveDelay
    }

    /// Where the Card is now, or `nil` once it's Discarded.
    private static func column(of card: NSManagedObject) -> Column? {
        column(after: visits(of: card))
    }

    /// The Column of the visit still going on. A Card without any events counts
    /// as in Backlog, which only a damaged or half-synced store has.
    private static func column(after visits: [ColumnVisit]) -> Column? {
        guard let last = visits.last else { return .backlog }
        return last.left == nil ? last.column : nil
    }

    /// The Card's Column Visits, replayed from its Created, Moved and Discarded
    /// events. Discarding ends the last visit without starting another.
    private static func visits(of card: NSManagedObject) -> [ColumnVisit] {
        visits(of: history(of: card))
    }

    /// The Column Visits that `history` (events in time order) adds up to.
    private static func visits(of history: [NSManagedObject]) -> [ColumnVisit] {
        var visits: [ColumnVisit] = []
        for event in history {
            guard let time = event.value(forKey: "timestamp") as? Date else { continue }
            switch (event.value(forKey: "kind") as? String).flatMap(Event.Kind.init) {
            case .created:
                visits.append(ColumnVisit(column: .backlog, entered: time))
            case .moved:
                guard let to = (event.value(forKey: "toColumn") as? String).flatMap(Column.init) else { continue }
                if !visits.isEmpty { visits[visits.count - 1].left = time }
                visits.append(ColumnVisit(column: to, entered: time))
            case .discarded:
                if !visits.isEmpty { visits[visits.count - 1].left = time }
            case .edited, .triaged, .wipLimitChanged, .creationBlocked, nil:
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
