import Foundation

/// A recorded fact from the event log: a Card Event (with its Card) or a Board
/// Event (without one). See GLOSSARY.md.
public struct Event: Equatable, Sendable {
    public enum Kind: String, Sendable {
        case created
        case moved
    }

    public let kind: Kind
    public let timestamp: Date
    public let cardID: UUID?
    /// Moved: the Columns the Card left and entered.
    public let from: Column?
    public let to: Column?

    public init(kind: Kind, timestamp: Date, cardID: UUID?, from: Column? = nil, to: Column? = nil) {
        self.kind = kind
        self.timestamp = timestamp
        self.cardID = cardID
        self.from = from
        self.to = to
    }
}
