import Foundation

/// A recorded fact from the event log: a Card Event (with its Card) or a Board
/// Event (without one). See GLOSSARY.md.
public struct Event: Equatable, Sendable {
    public enum Kind: String, Sendable {
        case created
        case moved
        case edited
        case discarded
        case triaged
        case wipLimitChanged
        case creationBlocked
    }

    public let kind: Kind
    public let timestamp: Date
    public let cardID: UUID?
    /// Moved: the Columns the Card left and entered.
    public let from: Column?
    public let to: Column?
    /// WIP Limit Changed: the old and the new limit.
    public let fromNumber: Int?
    public let toNumber: Int?
    /// Triaged: what the user did with the Card.
    public let triageOutcome: TriageOutcome?
    /// Creation Blocked: the Capacity and Open Card count at that moment.
    public let capacity: Int?
    public let openCards: Int?

    public init(kind: Kind, timestamp: Date, cardID: UUID?, from: Column? = nil, to: Column? = nil,
                fromNumber: Int? = nil, toNumber: Int? = nil, triageOutcome: TriageOutcome? = nil, capacity: Int? = nil, openCards: Int? = nil) {
        self.kind = kind
        self.timestamp = timestamp
        self.cardID = cardID
        self.from = from
        self.to = to
        self.fromNumber = fromNumber
        self.toNumber = toNumber
        self.triageOutcome = triageOutcome
        self.capacity = capacity
        self.openCards = openCards
    }
}

/// What the user did with the Card a Triage showed them (GLOSSARY.md).
public enum TriageOutcome: String, Sendable {
    /// Moved to Doing.
    case started
    case discarded
    /// Explicitly left where it is, with its Urgency unchanged.
    case kept
    /// The sheet was closed before deciding.
    case dismissed
}
