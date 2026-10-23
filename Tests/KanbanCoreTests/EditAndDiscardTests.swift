import Foundation
import Testing
@testable import KanbanCore

@MainActor
struct EditAndDiscardTests {
    let clock = TestClock()
    let board: Board

    init() throws {
        let clock = clock
        board = try Board(storeURL: nil, now: { clock.now })
    }

    private func create(_ title: String, notes: String = "") throws -> UUID {
        try board.createCard(title: title, notes: notes)
        return try #require(try board.cards(in: .backlog).first { $0.title == title }).id
    }

    private func card(_ id: UUID, in column: Column) throws -> Card {
        try #require(try board.cards(in: column).first { $0.id == id })
    }

    @Test func editingChangesTheCardAndRecordsOneEditedEvent() throws {
        let id = try create("Draft", notes: "rough")
        clock.advance(days: 1)

        try board.edit(id, title: "Final title", notes: "polished")

        let edited = try card(id, in: .backlog)
        #expect((edited.title, edited.notes) == ("Final title", "polished"))
        #expect(try board.events().last == Event(kind: .edited, timestamp: clock.now, cardID: id))
    }

    @Test func anEditThatChangesNothingRecordsNothing() throws {
        let id = try create("Same", notes: "as before")
        let eventsBefore = try board.events()

        try board.edit(id, title: "  Same ", notes: "as before\n")

        #expect(try board.events() == eventsBefore)
    }

    @Test func anEditNeedsATitle() throws {
        let id = try create("Keep")
        let eventsBefore = try board.events()

        #expect(throws: BoardError.emptyTitle) { try board.edit(id, title: " ", notes: "only notes") }
        #expect(try card(id, in: .backlog).title == "Keep")
        #expect(try board.events() == eventsBefore)
    }

    @Test func editingDoesNotMakeACardYounger() throws {
        let waiting = try create("Waiting")
        let started = try create("Started")
        try board.move(started, to: .doing)
        clock.advance(days: 12)

        try board.edit(waiting, title: "Waiting, renamed", notes: "")
        try board.edit(started, title: "Started, renamed", notes: "")

        // Within a second: events in the same instant are stamped 1 ms apart (ADR 0002).
        #expect(abs(try #require(try card(waiting, in: .backlog).age) - 12 * 86_400) < 1)
        #expect(abs(try #require(try card(started, in: .doing).age) - 12 * 86_400) < 1)
    }

    @Test func doneCardsCannotBeEdited() throws {
        let id = try create("Finished")
        try board.move(id, to: .doing)
        try board.move(id, to: .done)
        let eventsBefore = try board.events()

        #expect(throws: BoardError.cardIsDone) { try board.edit(id, title: "Rewritten", notes: "") }
        #expect(try card(id, in: .done).title == "Finished")
        #expect(try board.events() == eventsBefore)
    }

    @Test(arguments: [Column.backlog, .doing])
    func discardingTakesAnOpenCardOffTheBoard(from column: Column) throws {
        let id = try create("Never mind")
        if column == .doing { try board.move(id, to: .doing) }
        clock.advance(days: 2)

        try board.discard(id)

        #expect(try board.cards(in: column).isEmpty)
        #expect(try board.events().last == Event(kind: .discarded, timestamp: clock.now, cardID: id))
    }

    @Test func doneCardsCannotBeDiscarded() throws {
        let id = try create("Finished")
        try board.move(id, to: .doing)
        try board.move(id, to: .done)
        let eventsBefore = try board.events()

        #expect(throws: BoardError.cardIsDone) { try board.discard(id) }
        #expect(try board.cards(in: .done).map(\.id) == [id])
        #expect(try board.events() == eventsBefore)
    }

    @Test func aDiscardedCardIsGoneForGood() throws {
        let id = try create("Gone")
        try board.discard(id)
        let eventsBefore = try board.events()

        #expect(throws: BoardError.cardNotFound) { try board.move(id, to: .doing) }
        #expect(throws: BoardError.cardNotFound) { try board.edit(id, title: "Back?", notes: "") }
        #expect(throws: BoardError.cardNotFound) { try board.discard(id) }
        #expect(try board.events() == eventsBefore)
    }

    @Test func discardingADoingCardFreesItsWIPSlot() throws {
        let board = try Board(storeURL: nil, now: { [clock] in clock.now }, wipLimit: 1)
        try board.createCard(title: "A", notes: "")
        try board.createCard(title: "B", notes: "")
        let (a, b) = try { let ids = try board.cards(in: .backlog).map(\.id); return (ids[0], ids[1]) }()
        try board.move(a, to: .doing)

        try board.discard(a)
        try board.move(b, to: .doing)

        #expect(try board.wipStatus() == WIPStatus(count: 1, limit: 1))
    }
}
