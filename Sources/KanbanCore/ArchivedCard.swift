import Foundation

/// A Card in the Archive: a Done Card that left the Board, or a Discarded Card.
/// Read-only. Which of the two it is follows from the `Archive` list it's in.
public struct ArchivedCard: Equatable, Identifiable, Sendable {
    public let card: Card
    public let created: Date
    /// When it entered Done or was Discarded.
    public let ended: Date

    public var id: UUID { card.id }
}

/// The Archive as the window shows it (spec 0003): Done Cards and Discarded
/// Cards apart, each the most recently ended first.
public struct Archive: Equatable, Sendable {
    /// Ended is when the Card entered Done, also for one archived by hand.
    public let done: [ArchivedCard]
    /// Ended is when the Card was Discarded.
    public let discarded: [ArchivedCard]

    public var isEmpty: Bool { done.isEmpty && discarded.isEmpty }
    /// Every archived Card: Done first, then Discarded.
    public var all: [ArchivedCard] { done + discarded }
}
