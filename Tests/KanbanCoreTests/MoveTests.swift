import Foundation
import Testing
@testable import KanbanCore

@MainActor
struct MoveTests {
    let clock = TestClock()
    let board: Board

    init() throws {
        let clock = clock
        board = try Board(storeURL: nil, now: { clock.now })
    }

    /// Creates a Card and returns its ID.
    private func create(_ title: String) throws -> UUID {
        try board.createCard(title: title, notes: "")
        return try #require(try board.cards(in: .backlog).first { $0.title == title }).id
    }

    @Test func startingACardMovesItFromBacklogToDoing() throws {
        let card = try create("Write the spec")

        try board.move(card, to: .doing)

        #expect(try board.cards(in: .backlog).isEmpty)
        #expect(try board.cards(in: .doing).map(\.id) == [card])
    }

    @Test func everyMoveRecordsOneMovedEventWithItsColumns() throws {
        let card = try create("Write the spec")
        clock.advance(days: 1)
        try board.move(card, to: .doing)
        let movedAt = clock.now

        #expect(try board.events().last == Event(kind: .moved, timestamp: movedAt, cardID: card, from: .backlog, to: .doing))
        #expect(try board.events().count == 2)
    }

    /// Puts a new Card in `column` the allowed way and returns its ID.
    private func card(in column: Column) throws -> UUID {
        let card = try create("Card in \(column.title)")
        if column != .backlog { try board.move(card, to: .doing) }
        if column == .done { try board.move(card, to: .done) }
        return card
    }

    @Test(arguments: [
        (Column.backlog, Column.done),  // nothing skips Doing
        (.done, .doing), (.done, .backlog),  // nothing leaves Done
        (.backlog, .backlog), (.doing, .doing), (.done, .done),
    ])
    func refusedMovesChangeNothing(from: Column, to: Column) throws {
        let card = try card(in: from)
        let eventsBefore = try board.events()

        #expect(throws: BoardError.moveNotAllowed(from: from, to: to)) { try board.move(card, to: to) }
        #expect(try board.cards(in: from).map(\.id) == [card])
        #expect(try board.events() == eventsBefore)
    }

    @Test func aCardCanGoBackFromDoingToBacklog() throws {
        let card = try card(in: .doing)

        try board.move(card, to: .backlog)

        #expect(try board.cards(in: .backlog).map(\.id) == [card])
        #expect(try board.cards(in: .doing).isEmpty)
    }

    @Test func doingListsTheLongestInDoingFirstCountingEveryVisit() throws {
        let y = try create("Y")  // created first, so creation order alone would list Y first
        let x = try create("X")
        try board.move(x, to: .doing)
        clock.advance(days: 3)
        try board.move(x, to: .backlog)  // 3 days in Doing so far
        try board.move(y, to: .doing)
        clock.advance(days: 1)
        try board.move(x, to: .doing)
        clock.advance(days: 2)  // X: 3 + 2 = 5 days in Doing; Y: 3 days

        #expect(try board.cards(in: .doing).map(\.id) == [x, y])
    }

    @Test func doneListsTheMostRecentlyFinishedFirst() throws {
        let first = try card(in: .doing)
        let second = try card(in: .doing)
        clock.advance(days: 1)
        try board.move(first, to: .done)
        clock.advance(days: 1)
        try board.move(second, to: .done)

        #expect(try board.cards(in: .done).map(\.id) == [second, first])
    }

    @Test func movingAnUnknownCardIsRefused() throws {
        #expect(throws: BoardError.cardNotFound) { try board.move(UUID(), to: .doing) }
        #expect(try board.events().isEmpty)
    }
}
