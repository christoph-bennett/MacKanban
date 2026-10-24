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
