import Foundation

/// How many Open Cards the Board allows right now, with what makes it up
/// (ADR 0001): base + Throughput − aging, rounded down, capped, no floor.
public struct Capacity: Equatable, Sendable {
    public nonisolated static let base = 5
    public nonisolated static let cap = 20
    /// Throughput counts the Cards that entered Done within this many days...
    public nonisolated static let throughputWindowDays = 14
    /// ...that is, within this long.
    public nonisolated static let throughputWindow = TimeInterval(throughputWindowDays) * 86_400

    /// Cards that entered Done within `throughputWindow`; Discarded Cards don't count.
    public let throughput: Int
    /// The Urgency of every Open Card added up.
    public let aging: Double
    /// Cards in Backlog and Doing.
    public let openCards: Int

    /// Base + Throughput − aging, before rounding down and the cap.
    public var unrounded: Double { Double(Self.base + throughput) - aging }

    public var total: Int {
        // The tolerance keeps floating-point error in the summed Urgencies (0.1 + 0.2
        // + 0.7 is a hair over 1) from rounding a whole slot away.
        min(Self.cap, Int((unrounded + 1e-9).rounded(.down)))
    }

    /// Slots left for new Cards; 0 or less means creating is blocked.
    public var free: Int { total - openCards }
}
