import Foundation
import Testing
@testable import KanbanCore

@MainActor
struct UrgencyTests {
    let clock = TestClock()
    let board: Board

    init() throws {
        let clock = clock
        board = try Board(storeURL: nil, now: { clock.now })
    }

    private func create(_ title: String) throws -> UUID {
        try board.createCard(title: title, notes: "")
        return try #require(try board.cards(in: .backlog).first { $0.title == title }).id
    }

    private func card(_ id: UUID, in column: Column) throws -> Card {
        try #require(try board.cards(in: column).first { $0.id == id })
    }

    @Test(arguments: [(0.0, 0.0), (3, 0), (12, 0.5), (21, 1), (30, 1)])
    func backlogUrgencyRisesWithCardAge(days: Double, urgency: Double) throws {
        let id = try create("Old idea")
        clock.advance(days: days)

        #expect(try card(id, in: .backlog).urgency == urgency)
    }

    @Test func anOldCardJustStartedIsNeutralInDoing() throws {
        let id = try create("Finally")
        clock.advance(days: 29)
        try board.move(id, to: .doing)
        clock.advance(days: 1)

        #expect(try card(id, in: .doing).urgency == 0)
    }

    @Test func doingUrgencyCountsEveryVisit() throws {
        let id = try create("Stuck")
        try board.move(id, to: .doing)
        clock.advance(days: 3)
        try board.move(id, to: .backlog)
        clock.advance(days: 10)  // time back in Backlog doesn't count for Doing
        try board.move(id, to: .doing)
        clock.advance(days: 1)  // 3 + 1 = 4 days in Doing

        #expect(abs(try card(id, in: .doing).urgency - 0.5) < 0.000_001)
    }

    @Test func doneCardsHaveNoUrgency() throws {
        let id = try create("Shipped")
        clock.advance(days: 30)
        try board.move(id, to: .doing)
        clock.advance(days: 30)
        try board.move(id, to: .done)

        #expect(try card(id, in: .done).urgency == 0)
    }

    @Test func theAgeLabelShowsCardAgeInBacklogAndColumnAgeInDoing() throws {
        let id = try create("Labelled")
        clock.advance(days: 12)
        #expect(try card(id, in: .backlog).age == 12 * 86_400)

        try board.move(id, to: .doing)
        clock.advance(days: 4)
        #expect(try card(id, in: .doing).age == 4 * 86_400)

        try board.move(id, to: .done)
        #expect(try card(id, in: .done).age == nil)
    }
}
