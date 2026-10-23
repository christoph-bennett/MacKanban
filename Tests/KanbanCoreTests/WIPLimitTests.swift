import Foundation
import Testing
@testable import KanbanCore

@MainActor
struct WIPLimitTests {
    let clock = TestClock()
    let board: Board

    init() throws {
        let clock = clock
        board = try Board(storeURL: nil, now: { clock.now }, wipLimit: 2)
    }

    private func create(_ title: String) throws -> UUID {
        try board.createCard(title: title, notes: "")
        return try #require(try board.cards(in: .backlog).first { $0.title == title }).id
    }

    @Test func startingACardIsRefusedWhenDoingIsAtTheWIPLimit() throws {
        try board.move(try create("A"), to: .doing)
        try board.move(try create("B"), to: .doing)
        let third = try create("C")
        let eventsBefore = try board.events()

        #expect(throws: BoardError.wipLimitReached(limit: 2)) { try board.move(third, to: .doing) }
        #expect(try board.cards(in: .backlog).map(\.id) == [third])
        #expect(try board.events() == eventsBefore)
    }

    @Test func changingTheWIPLimitRecordsABoardEvent() throws {
        clock.advance(days: 1)
        try board.changeWIPLimit(to: 4)

        #expect(board.wipLimit == 4)
        #expect(try board.events() == [Event(kind: .wipLimitChanged, timestamp: clock.now, cardID: nil, fromNumber: 2, toNumber: 4)])
    }

    @Test func settingTheSameWIPLimitRecordsNothing() throws {
        try board.changeWIPLimit(to: 2)

        #expect(try board.events().isEmpty)
    }

    @Test(arguments: [0, 6])
    func theWIPLimitStaysBetweenOneAndFive(limit: Int) throws {
        #expect(throws: BoardError.wipLimitOutOfRange) { try board.changeWIPLimit(to: limit) }
        #expect(board.wipLimit == 2)
        #expect(try board.events().isEmpty)
    }

    @Test func loweringTheWIPLimitBelowDoingKeepsTheCardsButRefusesNewStarts() throws {
        let a = try create("A")
        let b = try create("B")
        try board.move(a, to: .doing)
        try board.move(b, to: .doing)
        let waiting = try create("C")

        try board.changeWIPLimit(to: 1)

        #expect(try board.cards(in: .doing).count == 2)
        #expect(try board.wipStatus() == WIPStatus(count: 2, limit: 1))
        #expect(try board.wipStatus().isOverLimit)
        #expect(throws: BoardError.wipLimitReached(limit: 1)) { try board.move(waiting, to: .doing) }

        try board.move(a, to: .backlog)  // always allowed
        #expect(try board.wipStatus() == WIPStatus(count: 1, limit: 1))
        #expect(try !board.wipStatus().isOverLimit)
    }

    @Test(arguments: [0, 9])
    func aStoredWIPLimitOutsideTheRangeBecomesTheDefault(stored: Int) throws {
        #expect(try Board(storeURL: nil, wipLimit: stored).wipLimit == 3)
    }

    @Test func aMoveCanBeCheckedBeforeItIsMade() throws {
        try board.move(try create("A"), to: .doing)
        let waiting = try create("B")
        #expect(try board.moveRefusal(waiting, to: .doing) == nil)
        #expect(try board.moveRefusal(waiting, to: .done) == .moveNotAllowed(from: .backlog, to: .done))

        try board.move(waiting, to: .doing)  // Doing is full now
        let third = try create("C")
        let eventsBefore = try board.events()

        #expect(try board.moveRefusal(third, to: .doing) == .wipLimitReached(limit: 2))
        #expect(try board.events() == eventsBefore)
    }
}
