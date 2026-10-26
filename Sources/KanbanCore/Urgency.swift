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

    private static func days(_ count: Double) -> TimeInterval { count * 86_400 }
    private static func hours(_ count: Double) -> TimeInterval { count * 3_600 }
}
