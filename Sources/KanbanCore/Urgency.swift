import Foundation

/// How strongly a Card signals that it needs attention, from 0 (neutral) to 1
/// (full red): nothing during a grace period, then a linear rise. The
/// thresholds are fixed, not settings (ADR 0001).
enum Urgency {
    /// Backlog Cards by Card Age, Doing Cards by Column Age.
    private static let ramps: [Column: (neutralUntil: TimeInterval, fullAt: TimeInterval)] = [
        .backlog: (hours(12), days(21)),
        .doing: (hours(4), days(7)),
    ]

    /// Done Cards have none.
    static func of(age: TimeInterval, in column: Column) -> Double {
        guard let ramp = ramps[column] else { return 0 }
        return min(1, max(0, (age - ramp.neutralUntil) / (ramp.fullAt - ramp.neutralUntil)))
    }

    /// When a Card in this Column is fully red; none for Done.
    static func fullAt(in column: Column) -> TimeInterval? { ramps[column]?.fullAt }

    private static func days(_ count: Double) -> TimeInterval { count * 86_400 }
    private static func hours(_ count: Double) -> TimeInterval { count * 3_600 }
}

/// A Card's age as its label and hover text show it: under an hour, else whole
/// hours under a day, else whole days, always rounded down.
public enum AgeAmount: Equatable, Sendable {
    case underAnHour
    case hours(Int)
    case days(Int)

    public init(_ age: TimeInterval) {
        self = switch age {
        case ..<3_600: .underAnHour
        case ..<86_400: .hours(Int(age / 3_600))
        default: .days(Int(age / 86_400))
        }
    }
}

public extension Card {
    /// The hover text that explains the Card's colour (MVP 20): its age, measured
    /// as its age label measures it, and how fast its Column turns red compared
    /// with the other (ADR 0001). None in Done, where Cards have no Urgency.
    func urgencyExplanation(in column: Column) -> String? {
        let other: Column = column == .doing ? .backlog : .doing  // the two Columns with Urgency
        guard let age, let fullAt = Urgency.fullAt(in: column), let otherFullAt = Urgency.fullAt(in: other) else { return nil }
        func count(_ n: Int, _ unit: String) -> String { n == 1 ? "1 \(unit)" : "\(n) \(unit)s" }
        let ageText = switch AgeAmount(age) {
        case .underAnHour: "Less than an hour"
        case let .hours(n): count(n, "hour")
        case let .days(n): count(n, "day")
        }
        let sentence = column == .doing ? "\(ageText) in Doing." : "\(ageText) old."
        return "\(sentence) Cards in \(column.title) turn fully red after \(count(Int(fullAt / 86_400), "day")), "
            + "in \(other.title) after \(Int(otherFullAt / 86_400))."
    }
}
