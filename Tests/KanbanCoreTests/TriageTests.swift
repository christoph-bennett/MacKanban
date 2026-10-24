import Foundation
import Testing
@testable import KanbanCore

@MainActor
struct TriageTests {
    let clock = TestClock()
    let board: Board

    init() throws {
        let clock = clock
        board = try Board(storeURL: nil, now: { clock.now })
    }

    /// Creates a Card and returns its ID.
    private func create(_ title: String) throws -> UUID {
        try board.createCard(title: title, notes: "").cardID
    }

    @Test func theGateIsOpenWithThreeFreeSlotsAndTriagesWithTwo() throws {
        _ = try create("First")
        _ = try create("Second")
        #expect(try board.creationGate() == .open)  // Capacity 5, 3 free

        _ = try create("Third")
        guard case .triage = try board.creationGate() else { Issue.record("expected Triage with 2 free"); return }
    }

    @Test func theGateBlocksWithNoFreeSlots() throws {
        for index in 1...4 { _ = try create("Card \(index)") }
        guard case .triage = try board.creationGate() else { Issue.record("expected Triage with 1 free"); return }

        _ = try create("Card 5")
        #expect(try board.creationGate() == .blocked(capacity: 5, openCards: 5, cardsToFree: 1))
    }

    @Test func theBoardRefusesToCreateWhenBlocked() throws {
        for index in 1...5 { _ = try create("Card \(index)") }
        let eventsBefore = try board.events()

        #expect(throws: BoardError.creationBlocked(capacity: 5, openCards: 5, cardsToFree: 1)) {
            try board.createCard(title: "One too many", notes: "")
        }
        #expect(try board.cards(in: .backlog).count == 5)
        #expect(try board.events() == eventsBefore)
    }

    @Test func blockedCountsTheCardsToRemoveIncludingTheirAging() throws {
        for index in 1...4 { _ = try create("Red \(index)") }
        clock.advance(days: 21)  // 4 fully red Cards: Capacity 1, Open Cards 4

        // Discarding 2 gives Capacity 3 with 2 Open Cards: one slot free again.
        #expect(try board.creationGate() == .blocked(capacity: 1, openCards: 4, cardsToFree: 2))
        #expect(BoardError.creationBlocked(capacity: 1, openCards: 4, cardsToFree: 2).localizedDescription
            == "Capacity 1, Open Cards 4: finish or Discard 2 Cards.")
    }

    @Test func everyBlockedAttemptRecordsACreationBlockedEvent() throws {
        #expect(try board.attemptCreation() == .open)
        for index in 1...5 { _ = try create("Card \(index)") }
        let eventsBefore = try board.events()
        clock.advance(days: 0.01)

        #expect(try board.attemptCreation() == .blocked(capacity: 5, openCards: 5, cardsToFree: 1))
        let first = clock.now
        clock.advance(days: 0.01)
        _ = try board.attemptCreation()

        #expect(try board.events() == eventsBefore + [
            Event(kind: .creationBlocked, timestamp: first, cardID: nil, capacity: 5, openCards: 5),
            Event(kind: .creationBlocked, timestamp: clock.now, cardID: nil, capacity: 5, openCards: 5),
        ])
    }

    @Test(arguments: [TriageOutcome.kept, .dismissed])
    func keepingOrDismissingRecordsATriagedEventAndChangesNoUrgency(_ outcome: TriageOutcome) throws {
        let id = try create("Put off")
        clock.advance(days: 12)
        let before = try #require(try board.cards(in: .backlog).first)

        try board.triage(id, outcome: outcome)

        #expect(try board.cards(in: .backlog) == [before])
        #expect(try board.events().last == Event(kind: .triaged, timestamp: clock.now, cardID: id, triageOutcome: outcome))
    }

    @Test func startingMovesTheCardToDoingAndRecordsBothEvents() throws {
        let id = try create("Finally")
        clock.advance(days: 1)

        try board.triage(id, outcome: .started)

        #expect(try board.cards(in: .doing).map(\.id) == [id])
        #expect(try board.events().suffix(2) == [
            Event(kind: .moved, timestamp: clock.now, cardID: id, from: .backlog, to: .doing),
            Event(kind: .triaged, timestamp: clock.now + 0.001, cardID: id, triageOutcome: .started),
        ])
    }

    @Test func startingIsRefusedAtTheWIPLimitAndRecordsNothing() throws {
        let board = try Board(storeURL: nil, now: { [clock] in clock.now }, wipLimit: 1)
        let busy = try board.createCard(title: "Busy", notes: "").cardID
        let waiting = try board.createCard(title: "Waiting", notes: "").cardID
        try board.move(busy, to: .doing)
        let eventsBefore = try board.events()

        #expect(throws: BoardError.wipLimitReached(limit: 1)) { try board.triage(waiting, outcome: .started) }
        #expect(try board.moveRefusal(waiting, to: .doing) == .wipLimitReached(limit: 1))  // what the sheet shows
        #expect(try board.events() == eventsBefore)
    }

    @Test func discardingTakesTheCardOffTheBoardAndRecordsBothEvents() throws {
        let id = try create("Never mind")
        clock.advance(days: 1)

        try board.triage(id, outcome: .discarded)

        #expect(try board.cards(in: .backlog).isEmpty)
        #expect(try board.events().suffix(2) == [
            Event(kind: .discarded, timestamp: clock.now, cardID: id),
            Event(kind: .triaged, timestamp: clock.now + 0.001, cardID: id, triageOutcome: .discarded),
        ])
    }

    @Test(arguments: [TriageOutcome.started, .discarded])
    func undoingAStartOrDiscardAlsoRemovesItsTriagedEvent(_ outcome: TriageOutcome) throws {
        let id = try create("Second thoughts")
        clock.advance(days: 1)
        let eventsBefore = try board.events()

        let change = try #require(try board.triage(id, outcome: outcome))
        try board.revert(change)

        #expect(try board.cards(in: .backlog).map(\.id) == [id])
        #expect(try board.events() == eventsBefore)
    }

    @Test(arguments: [TriageOutcome.kept, .dismissed])
    func keepingOrDismissingCantBeUndone(_ outcome: TriageOutcome) throws {
        let id = try create("Still here")

        #expect(try board.triage(id, outcome: outcome) == nil)
    }

    @Test func triageShowsTheCardWithTheHighestUrgencyEvenInDoing() throws {
        _ = try create("Waiting")
        let started = try create("Started")
        try board.move(started, to: .doing)
        clock.advance(days: 4)  // Backlog Urgency 1/18, Doing Urgency 0.5: Capacity 4, 2 free

        #expect(try board.creationGate() == .triage(try #require(try board.cards(in: .doing).first)))
    }

    @Test func aFullyRedCardTriagesEvenWithFreeSlots() throws {
        _ = try create("Ancient")
        clock.advance(days: 20.9)
        #expect(try board.creationGate() == .open)  // Urgency 0.99: Capacity 4, 3 free

        clock.advance(days: 0.1)  // Urgency 1, still 3 free
        #expect(try board.creationGate() == .triage(try #require(try board.cards(in: .backlog).first)))
    }
}
