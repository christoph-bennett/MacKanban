import Foundation

/// What the New Card sheet does before a Card can be created (spec 0001).
public enum CreationGate: Equatable, Sendable {
    /// Straight to title and notes.
    case open
    /// First a Triage of this Card, the Open Card with the highest Urgency.
    case triage(Card)
    /// No way to create: the Board has no free slot (Capacity minus Open Cards).
    /// `cardsToFree`: how many of the most urgent Open Cards to finish or Discard
    /// for one slot, counting the aging each takes with it.
    case blocked(capacity: Int, openCards: Int, cardsToFree: Int)

    /// Triage from this many free slots down (ADR 0001: a constant, not a setting).
    public nonisolated static let triageThreshold = 2
}

/// What a Restore of a Discarded Card would do and cost (ADR 0008): the same
/// three outcomes as creating, judged by the free slots left after the Restore,
/// since a restored Card brings its Urgency with it.
public struct RestoreGate: Equatable, Sendable {
    public enum Outcome: Equatable, Sendable {
        /// Straight back to Backlog.
        case open
        /// First a Triage of this Card, the Open Card with the highest Urgency.
        case triage(Card)
        /// No room: finish or Discard this many of the most urgent Open Cards first.
        case blocked(cardsToFree: Int)
    }

    public let outcome: Outcome
    /// The free slots the Restore would take: one for the Card and what its
    /// Urgency costs, counted as Capacity counts (rounded down).
    public let cost: Int
    /// The Card's Urgency in Backlog, and the Card Age it comes from.
    public let urgency: Double
    public let age: TimeInterval
    /// Free slots on the Board now, before the Restore.
    public let free: Int
}
