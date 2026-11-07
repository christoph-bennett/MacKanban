import Foundation

/// A Card in the Archive: a Done Card that left the Board, or a Discarded Card.
/// Read-only. Which of the two it is follows from the `Archive` list it's in.
public struct ArchivedCard: Equatable, Identifiable, Sendable {
    public let card: Card
    public let created: Date
    /// When it entered Done or was Discarded.
    public let ended: Date
    /// A Done Card: until when it counts toward Throughput, 14 days after it
    /// entered Done (Capacity's window, ADR 0001), past or not. `nil` for a
    /// Discarded Card, which never counts.
    public let countsUntil: Date?
    /// Whether Capacity counts it right now, by the same rule and clock.
    public let isCounting: Bool

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
    /// The moment the Archive was read, on the Board's clock: what `isCounting` and
    /// the time left until `countsUntil` are measured from.
    public let asOf: Date

    /// Every archived Card: Done first, then Discarded.
    public var all: [ArchivedCard] { done + discarded }
}
