import Testing
@testable import KanbanCore

struct ColumnTests {
    @Test func theBoardHasThreeFixedColumnsInFlowOrder() {
        #expect(Column.allCases == [.backlog, .doing, .done])
    }

    @Test func columnTitles() {
        #expect(Column.allCases.map(\.title) == ["Backlog", "Doing", "Done"])
    }
}
