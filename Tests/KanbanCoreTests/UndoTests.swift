import Foundation
import Testing
@testable import KanbanCore

@MainActor
struct UndoTests {
    let clock = TestClock()
    let board: Board

    init() throws {
        let clock = clock
        board = try Board(storeURL: nil, now: { clock.now })
    }

    private func card(_ id: UUID, in column: Column) throws -> Card {
        try #require(try board.cards(in: column).first { $0.id == id })
    }

    @Test func revertingAMoveDeletesItsEventAndKeepsTheAge() throws {
        let id = try board.createCard(title: "Slip", notes: "").cardID
        try board.move(id, to: .doing)
        clock.advance(days: 3)
        let mistake = try board.move(id, to: .done)
        let eventsBefore = try board.events().dropLast()

        try board.revert(mistake)
        clock.advance(days: 1)

        #expect(try board.cards(in: .done).isEmpty)
        #expect(abs(try #require(try card(id, in: .doing).age) - 4 * 86_400) < 1)
        #expect(try board.events() == Array(eventsBefore))
    }

    @Test func revertingADiscardBringsTheCardBack() throws {
        let id = try board.createCard(title: "Oops", notes: "").cardID
        try board.move(id, to: .doing)
        clock.advance(days: 2)
        let discard = try board.discard(id)

        try board.revert(discard)

        #expect(abs(try #require(try card(id, in: .doing).age) - 2 * 86_400) < 1)
        #expect(try !board.events().contains { $0.kind == .discarded })
    }

    @Test func revertingACreationLeavesNoTrace() throws {
        let creation = try board.createCard(title: "Typo", notes: "")

        try board.revert(creation)

        #expect(try board.cards(in: .backlog).isEmpty)
        #expect(try board.events().isEmpty)
    }

    @Test func onlyTheCardsLatestChangeCanBeReverted() throws {
        let creation = try board.createCard(title: "Busy", notes: "")
        let start = try board.move(creation.cardID, to: .doing)
        try board.move(creation.cardID, to: .done)
        let eventsBefore = try board.events()

        #expect(throws: BoardError.cannotUndo) { try board.revert(start) }
        #expect(throws: BoardError.cannotUndo) { try board.revert(creation) }
        #expect(try board.events() == eventsBefore)
    }

    @Test func redoingACreationKeepsTheCardsID() throws {
        let creation = try board.createCard(title: "Again", notes: "notes")
        try board.revert(creation)

        let redone = try board.createCard(title: "Again", notes: "notes", id: creation.cardID)
        try board.move(redone.cardID, to: .doing)

        #expect(try board.cards(in: .doing).map(\.id) == [creation.cardID])
    }

    @Test func aCardIDCanOnlyBeUsedOnce() throws {
        let id = try board.createCard(title: "First", notes: "").cardID

        #expect(throws: BoardError.cardExists) { try board.createCard(title: "Second", notes: "", id: id) }
        #expect(try board.cards(in: .backlog).map(\.title) == ["First"])
    }

    @Test func undoingIntoDoingRespectsTheWIPLimit() throws {
        let board = try Board(storeURL: nil, now: { [clock] in clock.now }, wipLimit: 1)
        let a = try board.createCard(title: "A", notes: "").cardID
        let b = try board.createCard(title: "B", notes: "").cardID
        try board.move(a, to: .doing)
        let backToBacklog = try board.move(a, to: .backlog)
        try board.move(b, to: .doing)  // Doing is full again
        let eventsBefore = try board.events()

        #expect(throws: BoardError.wipLimitReached(limit: 1)) { try board.revert(backToBacklog) }
        #expect(try board.events() == eventsBefore)
    }

    @Test func editsDoNotBlockUndo() throws {
        let creation = try board.createCard(title: "Typo", notes: "")
        try board.edit(creation.cardID, title: "Fixed", notes: "")
        let start = try board.move(creation.cardID, to: .doing)
        try board.edit(creation.cardID, title: "Fixed again", notes: "")

        try board.revert(start)
        try board.revert(creation)

        #expect(try board.cards(in: .backlog).isEmpty)
        #expect(try board.events().isEmpty)
    }

    @Test func aKeptTriageDoesNotBlockUndo() throws {
        let id = try board.createCard(title: "Started", notes: "").cardID
        let start = try board.move(id, to: .doing)
        try board.triage(id, outcome: .kept)

        try board.revert(start)

        #expect(try board.cards(in: .backlog).map(\.id) == [id])
    }

    @Test func undoIsForSlipsNotForRewritingHistory() throws {
        let id = try board.createCard(title: "Finished", notes: "").cardID
        try board.move(id, to: .doing)
        let finish = try board.move(id, to: .done)
        clock.advance(days: Board.undoWindow / 86_400 + 1 / 86_400)  // a second too late

        #expect(throws: BoardError.cannotUndo) { try board.revert(finish) }
        #expect(try board.cards(in: .done).map(\.id) == [id])
    }
}
