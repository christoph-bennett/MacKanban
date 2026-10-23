import Foundation

/// One stretch of time a Card spent in a Column (GLOSSARY.md). Never stored:
/// replayed from the Card's events (ADR 0002).
struct ColumnVisit: Equatable {
    let column: Column
    let entered: Date
    /// `nil` while the Card is still in the Column.
    var left: Date?
}

extension [ColumnVisit] {
    /// Column Age: the total time across every visit to `column`, up to `now`
    /// for the visit still going on (ADR 0001). A visit stamped after `now`, after
    /// the clock was turned back, counts as no time rather than negative time.
    func timeSpent(in column: Column, until now: Date) -> TimeInterval {
        filter { $0.column == column }
            .reduce(0) { $0 + Swift.max(0, ($1.left ?? now).timeIntervalSince($1.entered)) }
    }
}
