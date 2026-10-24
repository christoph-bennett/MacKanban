import Foundation

/// A Card in the Archive: a Done Card past `Board.archiveDelay`, or a Discarded
/// Card. Read-only.
public struct ArchivedCard: Equatable, Identifiable, Sendable {
    public enum Outcome: Sendable {
        case done
        case discarded
    }

    public let card: Card
    public let created: Date
    /// When it entered Done or was Discarded.
    public let ended: Date
    public let outcome: Outcome

    public var id: UUID { card.id }
}
