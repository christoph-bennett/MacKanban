import Foundation
import Testing
@testable import KanbanCore

/// A clock the tests move forward by hand.
final class TestClock: @unchecked Sendable {
    var now = Date(timeIntervalSince1970: 1_792_051_200)  // 2026-10-15, 00:00 UTC

    func advance(days: Double) { now += days * 86_400 }
}

@MainActor
struct BoardTests {
    let clock = TestClock()
    let board: Board

    init() throws {
        let clock = clock
        board = try Board(storeURL: nil, now: { clock.now })
    }

    @Test func aCreatedCardAppearsInBacklog() throws {
        try board.createCard(title: "Write the spec", notes: "With user stories")

        let backlog = try board.cards(in: .backlog)
        #expect(backlog.map(\.title) == ["Write the spec"])
        #expect(backlog.map(\.notes) == ["With user stories"])
        #expect(try board.cards(in: .doing).isEmpty)
        #expect(try board.cards(in: .done).isEmpty)
    }

    @Test func creatingACardRecordsOneCreatedEventAtTheCurrentTime() throws {
        try board.createCard(title: "Write the spec", notes: "")
        let card = try #require(try board.cards(in: .backlog).first)

        #expect(try board.events() == [Event(kind: .created, timestamp: clock.now, cardID: card.id)])
    }

    @Test func backlogListsCardsOldestFirst() throws {
        try board.createCard(title: "First", notes: "")
        clock.advance(days: 1)
        try board.createCard(title: "Second", notes: "")
        clock.advance(days: 1)
        try board.createCard(title: "Third", notes: "")

        #expect(try board.cards(in: .backlog).map(\.title) == ["First", "Second", "Third"])
    }

    @Test func aCardNeedsATitle() throws {
        #expect(throws: BoardError.emptyTitle) { try board.createCard(title: "  \n ", notes: "Notes alone") }
        #expect(try board.cards(in: .backlog).isEmpty)
        #expect(try board.events().isEmpty)
    }

    @Test func cardsAndEventsSurviveReopeningTheStore() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appendingPathComponent("Board.sqlite")
        let clock = clock

        try Board(storeURL: storeURL, now: { clock.now }).createCard(title: "Keep me", notes: "Really")
        let reopened = try Board(storeURL: storeURL, now: { clock.now })

        let card = try #require(try reopened.cards(in: .backlog).first)
        #expect((card.title, card.notes) == ("Keep me", "Really"))
        #expect(try reopened.events() == [Event(kind: .created, timestamp: clock.now, cardID: card.id)])
    }
}
