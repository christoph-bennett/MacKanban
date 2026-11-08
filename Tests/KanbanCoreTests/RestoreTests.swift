import Foundation
import Testing
@testable import KanbanCore

/// Restoring a Discarded Card from the Archive (spec 0005, ADR 0008).
@MainActor
struct RestoreTests {
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

    @Test func aRestoredCardIsBackInBacklogWithItsAgeAndOutOfTheArchive() throws {
        let id = try create("Plan the garden")
        clock.advance(days: 5)
        try board.discard(id)
        clock.advance(days: 16)

        try board.restore(id)

        let card = try #require(try board.cards(in: .backlog).first { $0.id == id })
        #expect(card.title == "Plan the garden")
        #expect(abs(try #require(card.age) - 21 * 86_400) < 1)  // Card Age runs on through the Archive
        #expect(card.urgency == 1)
        #expect(try board.archive().discarded.isEmpty)
    }

    @Test func onlyDiscardedCardsCanBeRestored() throws {
        let open = try create("Still open")
        let done = try create("Shipped")
        try board.move(done, to: .doing)
        try board.move(done, to: .done)
        clock.advance(days: 10)  // archived by the Archive Delay

        #expect(throws: BoardError.cardIsNotDiscarded) { try board.restore(open) }
        #expect(throws: BoardError.cardIsNotDiscarded) { try board.restore(done) }
        #expect(throws: BoardError.cardNotFound) { try board.restore(UUID()) }
    }

    @Test func aDiscardedSampleCardCantBeRestored() throws {
        try board.addSampleCards()
        let sample = try #require(try board.archive().discarded.first).id

        #expect(throws: BoardError.sampleCardCantBeRestored) { try board.restore(sample) }
    }

    @Test func aCardDiscardedFromDoingComesBackToBacklogAndKeepsItsDoingAge() throws {
        let id = try create("Stuck")
        try board.move(id, to: .doing)
        clock.advance(days: 3)
        try board.discard(id)
        clock.advance(days: 2)

        try board.restore(id)
        #expect(try board.cards(in: .backlog).contains { $0.id == id })
        clock.advance(days: 1)
        try board.move(id, to: .doing)
        clock.advance(days: 0.5)

        let age = try #require(try board.cards(in: .doing).first { $0.id == id }?.age)
        #expect(abs(age - 3.5 * 86_400) < 1)  // Column Age adds up across visits
    }

    @Test func discardedAgainItShowsOnceInTheArchiveWithTheLastDiscard() throws {
        let id = try create("Back and forth")
        try board.discard(id)
        clock.advance(days: 1)
        try board.restore(id)
        clock.advance(days: 1)
        try board.discard(id)

        let discarded = try board.archive().discarded
        #expect(discarded.map(\.id) == [id])
        #expect(abs(try #require(discarded.first).ended.timeIntervalSince(clock.now)) < 1)
    }

    @Test func undoWithinFifteenMinutesPutsItBackInTheArchive() throws {
        let id = try create("Oops")
        try board.discard(id)
        clock.advance(days: 1)
        let change = try board.restore(id)
        clock.advance(days: 10.0 / 1_440)  // 10 minutes

        try board.revert(change)

        #expect(try board.archive().discarded.map(\.id) == [id])
        #expect(try !board.cards(in: .backlog).contains { $0.id == id })
    }

    @Test func afterFifteenMinutesARestoreCantBeUndone() throws {
        let id = try create("Oops")
        try board.discard(id)
        let change = try board.restore(id)
        clock.advance(days: 16.0 / 1_440)

        #expect(throws: BoardError.cannotUndo) { try board.revert(change) }
    }

    /// A Card created `daysOld` days ago and Discarded right after: by now its
    /// Card Age, and so its Urgency in Backlog, is what it would be on the Board.
    private func discarded(_ title: String, daysOld: Double) throws -> UUID {
        let id = try create(title)
        try board.discard(id)
        clock.advance(days: daysOld)
        return id
    }

    @Test func withRoomTheGateIsOpenAndTheCostFollowsTheCardsAge() throws {
        let red = try discarded("Old", daysOld: 21)
        let fresh = try create("Fresh")
        try board.discard(fresh)

        let redGate = try board.restoreGate(red)
        #expect(redGate.outcome == .open)
        #expect(redGate.cost == 2)  // one slot, and 1.0 from its age
        #expect(redGate.free == 5)
        #expect(try board.restoreGate(fresh).cost == 1)
    }

    @Test func withoutRoomForItsWholeCostARestoreIsBlocked() throws {
        let red = try discarded("Old", daysOld: 21)
        let open = try (1...4).map { try create("Open \($0)") }  // fresh: 1 slot left

        let gate = try board.restoreGate(red)

        #expect(gate.outcome == .blocked(cardsToFree: 1))  // 1 slot free, the Card takes 2
        #expect((gate.cost, gate.free) == (2, 1))
        #expect(throws: BoardError.restoreBlocked(cost: 2, free: 1, cardsToFree: 1)) { try board.restore(red) }
        try board.discard(open[0])
        #expect(try board.restoreGate(red).outcome != .blocked(cardsToFree: 1))
    }

    @Test(arguments: [(2, true), (1, false)])
    func withOneSlotOrFewerLeftAfterwardsATriageComesFirst(openCards: Int, triage: Bool) throws {
        let red = try discarded("Old", daysOld: 21)
        let open = try (1...openCards).map { try create("Open \($0)") }

        let outcome = try board.restoreGate(red).outcome  // after it: 4 Capacity, openCards + 1 Open Cards

        #expect(outcome == (triage ? .triage(try #require(try board.cards(in: .backlog).first { $0.id == open[0] })) : .open))
    }

    @Test func aFullyRedOpenCardMeansTriageEvenWithRoom() throws {
        let id = try discarded("Discarded", daysOld: 0)
        let old = try create("Old and open")
        clock.advance(days: 21)

        #expect(try board.restoreGate(id).outcome == .triage(try #require(try board.cards(in: .backlog).first { $0.id == old })))
    }

    @Test func theCostCountsAsCapacityCountsRoundingIncluded() throws {
        let other = try create("Aging")  // Urgency 0.6 by the end
        clock.advance(days: 4.1)
        let id = try create("Discarded")  // Urgency 0.4 by the end
        try board.discard(id)
        clock.advance(days: 8.7)

        #expect(try board.restoreGate(id).cost == 1)  // 4.4 rounds down to 4, and 4.0 stays 4
        try board.discard(other)
        #expect(try board.restoreGate(id).cost == 2)  // 5 slots, then 4.6 rounds down to 4
    }

    @Test func aRefusedRestoreRecordsNothing() throws {
        let red = try discarded("Old", daysOld: 21)
        _ = try (1...4).map { try create("Open \($0)") }
        let before = try board.events()

        _ = try? board.restore(red)

        #expect(try board.events() == before)  // no Restored event, no Creation Blocked
    }

    @Test func capacityCountsTheRestoredCardAndThroughputStays() throws {
        let red = try discarded("Old", daysOld: 21)
        let before = try board.capacity()

        try board.restore(red)

        let after = try board.capacity()
        #expect((after.openCards, after.throughput) == (before.openCards + 1, before.throughput))
        #expect(after.free == before.free - 2)
    }

    @Test func aRestoreThatNeedsATriageIsRefusedUntilItHappened() throws {
        let red = try discarded("Old", daysOld: 21)
        _ = try (1...2).map { try create("Open \($0)") }  // one slot left after it

        #expect(throws: BoardError.restoreNeedsTriage) { try board.restore(red) }
        try board.restore(red, afterTriage: true)
        #expect(try board.cards(in: .backlog).contains { $0.id == red })
    }

    @Test func afterATriageTheGateIsCheckedAgain() throws {
        let red = try discarded("Old", daysOld: 0)
        let stale = try create("Stale and open")
        clock.advance(days: 21)  // both fully red now; the open one asks for a Triage
        let triaged = try #require(try board.cards(in: .backlog).first { $0.id == stale })
        #expect(try board.restoreGate(red).outcome == .triage(triaged))

        try board.triage(stale, outcome: .discarded)

        #expect(try board.restoreGate(red).outcome == .open)
        try board.restore(red)  // no Triage needed any more
    }

    @Test func keepingTheCardInTheTriageStillLetsTheRestoreThrough() throws {
        let red = try discarded("Old", daysOld: 0)
        let stale = try create("Stale and open")
        clock.advance(days: 21)

        try board.triage(stale, outcome: .kept)

        #expect(throws: BoardError.restoreNeedsTriage) { try board.restore(red) }  // still asks
        try board.restore(red, afterTriage: true)
        #expect(try board.cards(in: .backlog).contains { $0.id == red })
    }

    @Test func whenTheRoomIsGoneByTheTimeTheTriageIsDoneTheRestoreIsBlocked() throws {
        let red = try discarded("Old", daysOld: 21)
        let open = try (1...3).map { try create("Open \($0)") }  // fresh: after the Restore, 0 slots left
        #expect(try board.restoreGate(red).outcome == .triage(try #require(try board.cards(in: .backlog).first { $0.id == open[0] })))

        try board.triage(open[0], outcome: .kept)
        clock.advance(days: 7)  // the open Cards age while the sheet is up

        guard case .blocked = try board.restoreGate(red).outcome else { Issue.record("expected blocked"); return }
        #expect(throws: BoardError.self) { try board.restore(red, afterTriage: true) }
    }
}
