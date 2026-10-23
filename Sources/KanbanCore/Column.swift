/// One of the Board's three fixed Columns, in the order Cards flow through them.
public enum Column: String, CaseIterable, Sendable {
    case backlog
    case doing
    case done

    public var title: String {
        switch self {
        case .backlog: "Backlog"
        case .doing: "Doing"
        case .done: "Done"
        }
    }
}
