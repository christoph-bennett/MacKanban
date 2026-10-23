import Foundation

/// A recorded fact from the event log: a Card Event (with its Card) or a Board
/// Event (without one). See GLOSSARY.md.
public struct Event: Equatable, Sendable {
    public enum Kind: String, Sendable {
        case created
    }

    public let kind: Kind
    public let timestamp: Date
    public let cardID: UUID?

    public init(kind: Kind, timestamp: Date, cardID: UUID?) {
        self.kind = kind
        self.timestamp = timestamp
        self.cardID = cardID
    }
}
