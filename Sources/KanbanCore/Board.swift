import CoreData
import Foundation

/// A Card as the Board shows it.
public struct Card: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let notes: String
}

/// Why the Board refused an operation.
public enum BoardError: LocalizedError, Equatable {
    case emptyTitle

    public var errorDescription: String? {
        switch self {
        case .emptyTitle: "A Card needs a title."
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

    /// - Parameter storeURL: the SQLite file, or `nil` for a store that lives only in memory.
    public init(storeURL: URL?, now: @escaping () -> Date = Date.init) throws {
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
        let card = NSManagedObject(entity: StoreModel.shared.entitiesByName["Card"]!, insertInto: context)
        card.setValue(UUID(), forKey: "id")
        card.setValue(title, forKey: "title")
        card.setValue(notes.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "notes")
        let event = NSManagedObject(entity: StoreModel.shared.entitiesByName["Event"]!, insertInto: context)
        event.setValue(Event.Kind.created.rawValue, forKey: "kind")
        event.setValue(now(), forKey: "timestamp")
        event.setValue(card, forKey: "card")
        try save()
    }

    /// Saves, or drops the unsaved changes so the Board never shows what isn't stored.
    private func save() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    public func cards(in column: Column) throws -> [Card] {
        guard column == .backlog else { return [] }
        let request = NSFetchRequest<NSManagedObject>(entityName: "Card")
        request.relationshipKeyPathsForPrefetching = ["events"]
        return try context.fetch(request)
            .map { (createdAt: Self.createdAt($0), object: $0) }
            .sorted { $0.createdAt < $1.createdAt }
            .compactMap { Self.card($0.object) }
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
            return Event(kind: kind, timestamp: timestamp, cardID: card?.value(forKey: "id") as? UUID)
        }
    }

    /// When the Card's Created event happened.
    private static func createdAt(_ card: NSManagedObject) -> Date {
        let events = card.value(forKey: "events") as? Set<NSManagedObject> ?? []
        return events.first { $0.value(forKey: "kind") as? String == Event.Kind.created.rawValue }?
            .value(forKey: "timestamp") as? Date ?? .distantPast
    }

    /// `nil` for a row without an ID, which only a damaged or half-synced store has.
    private static func card(_ object: NSManagedObject) -> Card? {
        guard let id = object.value(forKey: "id") as? UUID else { return nil }
        return Card(id: id,
                    title: object.value(forKey: "title") as? String ?? "",
                    notes: object.value(forKey: "notes") as? String ?? "")
    }
}
