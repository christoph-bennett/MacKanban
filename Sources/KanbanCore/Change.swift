import Foundation

/// What one Board operation recorded, so it can be undone: the Card and the
/// event the operation appended (ADR 0002: undo deletes it).
public struct Change: Equatable, Sendable {
    public let cardID: UUID
    /// A creation is undone by deleting the Card with its events.
    let isCreation: Bool
    /// The event's Core Data object ID, as a URL.
    let event: URL
}
