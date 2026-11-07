import Foundation
import Testing
@testable import KanbanCore

@MainActor
struct ArchiveTests {
    let clock = TestClock()
    let board: Board

    init() throws {
        let clock = clock
        board = try Board(storeURL: nil, now: { clock.now })
    }

    /// Creates a Card and takes it through Doing to Done over a day, finishing at
    /// exactly the new `clock.now` (events in the same instant are stamped 1 ms apart).
    private func finish(_ title: String, on board: Board? = nil) throws -> UUID {
        let board = board ?? self.board
        let id = try board.createCard(title: title, notes: "").cardID
        clock.advance(days: 0.5)
        try board.move(id, to: .doing)
        clock.advance(days: 0.5)
        try board.move(id, to: .done)
        return id
    }

    @Test func aDoneCardLeavesTheBoardThreeDaysAfterEnteringDoneByDefault() throws {
        #expect(board.archiveDelay == 3)
        let id = try finish("Shipped")
        let events = try board.events()

        clock.advance(days: 2.99)
        #expect(try board.cards(in: .done).map(\.id) == [id])

        clock.advance(days: 0.01)
        #expect(try board.cards(in: .done).isEmpty)
        #expect(try board.archive().done.map(\.id) == [id])
        #expect(try board.events() == events)  // archiving follows from the rule, it isn't recorded
    }

    @Test func aDoneCardsAgeIsHowLongItHasBeenInDoneWithoutUrgency() throws {
        let id = try board.createCard(title: "Shipped", notes: "").cardID
        clock.advance(days: 5)
        try board.move(id, to: .doing)
        clock.advance(days: 2)
        try board.move(id, to: .done)
        clock.advance(days: 1.5)

        let card = try #require(try board.cards(in: .done).first)
        #expect(abs(try #require(card.age) - 1.5 * 86_400) < 1)  // time in Done, not its 8.5-day Card Age
        #expect(card.urgency == 0)
    }

    @Test func aDoneCardLeavesTheBoardOnceTheChosenArchiveDelayIsUp() throws {
        let board = try Board(storeURL: nil, now: { [clock] in clock.now }, archiveDelay: 7)
        let id = try finish("Shipped", on: board)

        clock.advance(days: 6.9)
        #expect(try board.cards(in: .done).map(\.id) == [id])
        clock.advance(days: 0.1)
        #expect(try board.cards(in: .done).isEmpty)
    }

    @Test func changingTheArchiveDelayAppliesAtOnceToEveryDoneCard() throws {
        let old = try finish("Old")
        clock.advance(days: 1.5)
        let recent = try finish("Recent")  // Old has been in Done for 2.5 days
        clock.advance(days: 0.5)  // Old: 3 days in Done, so archived; Recent: half a day
        #expect(try board.cards(in: .done).map(\.id) == [recent])

        try board.changeArchiveDelay(to: 5)  // lengthening brings Old back
        #expect(try board.cards(in: .done).map(\.id) == [recent, old])
        #expect(try board.archive().isEmpty)

        try board.changeArchiveDelay(to: 1)  // shortening archives Old straight away
        #expect(board.archiveDelay == 1)
        #expect(try board.cards(in: .done).map(\.id) == [recent])
        #expect(try board.archive().done.map(\.id) == [old])
    }

    @Test func changingTheArchiveDelayRecordsNothingAndLeavesThroughputAlone() throws {
        _ = try finish("Shipped")
        let events = try board.events()
        let throughput = try board.capacity().throughput

        try board.changeArchiveDelay(to: 1)
        clock.advance(days: 1)
        #expect(try board.cards(in: .done).isEmpty)
        #expect(try board.events() == events)
        #expect(try board.capacity().throughput == throughput)
    }

    @Test func theArchiveDelaysOnOfferAreOneToSevenDays() {
        #expect(Board.archiveDelays == [1, 2, 3, 5, 7])
    }

    @Test(arguments: [0, 4, 8, -1])
    func aStoredArchiveDelayNotOnOfferBecomesTheDefault(stored: Int) throws {
        #expect(try Board(storeURL: nil, archiveDelay: stored).archiveDelay == 3)
    }

    @Test func anArchiveDelayNotOnOfferIsRefused() throws {
        #expect(throws: BoardError.archiveDelayNotOffered) { try board.changeArchiveDelay(to: 4) }
        #expect(board.archiveDelay == 3)
    }

    @Test func theArchiveListsArchivedDoneCardsWithTheirDates() throws {
        let created = clock.now
        let id = try finish("Shipped")
        let finished = clock.now
        #expect(try board.archive().isEmpty)  // still on the Board

        clock.advance(days: 7)
        let archived = try #require(try board.archive().done.first)

        #expect((archived.card.id, archived.card.title) == (id, "Shipped"))
        #expect((archived.created, archived.ended) == (created, finished))
    }

    @Test func discardedCardsGoStraightToTheArchiveNewestFirst() throws {
        let shipped = try finish("Shipped")
        clock.advance(days: 7)  // archived
        let dropped = try board.createCard(title: "Dropped", notes: "").cardID
        clock.advance(days: 1)
        try board.discard(dropped)
        let discarded = clock.now
        clock.advance(days: 1)
        let later = try board.createCard(title: "Later", notes: "").cardID
        try board.discard(later)

        let archive = try board.archive()
        #expect(archive.done.map(\.id) == [shipped])
        #expect(archive.discarded.map(\.id) == [later, dropped])
        #expect(archive.discarded[1].ended == discarded)
    }

    @Test func theArchiveListsDoneCardsByWhenTheyWereFinishedNewestFirst() throws {
        let first = try finish("First")
        let second = try finish("Second")
        try board.archiveCard(second)  // archived by hand first, but finished later
        clock.advance(days: 3)  // First leaves after the delay
        let third = try finish("Third")
        try board.archiveCard(third)

        #expect(try board.archive().done.map(\.id) == [third, second, first])
        #expect(try board.archive().discarded.isEmpty)
    }

    @Test func anArchivedDoneCardSaysUntilWhenItCountsAsThroughput() throws {
        try board.changeArchiveDelay(to: 3)
        let byDelay = try finish("By delay")
        let finished = clock.now
        let byHand = try finish("By hand")
        let handFinished = clock.now
        try board.archiveCard(byHand)
        clock.advance(days: 3)  // By delay: 4 days in Done, past the 3-day delay

        let done = try board.archive().done
        #expect(done.map(\.id) == [byHand, byDelay])  // both archived, one each way
        #expect(done.allSatisfy { $0.isCounting })
        #expect(done[1].countsUntil == finished.addingTimeInterval(14 * 86_400))
        #expect(done[0].countsUntil == handFinished.addingTimeInterval(14 * 86_400))
    }

    @Test func throughputCountsAnArchivedCardExactlyUntilItsCountsUntil() throws {
        _ = try finish("Shipped")
        clock.advance(days: 3)
        let until = try #require(try board.archive().done.first?.countsUntil)

        for (moment, counts) in [(until.addingTimeInterval(-60), true), (until, true), (until.addingTimeInterval(60), false)] {
            clock.now = moment
            #expect(try board.capacity().throughput == (counts ? 1 : 0))
            let entry = try #require(try board.archive().done.first)
            #expect(entry.isCounting == counts)  // the same rule and clock as Capacity
            #expect(entry.countsUntil == until)  // still listed after it stops counting
        }
    }

    @Test func discardedCardsNeverCount() throws {
        let id = try board.createCard(title: "Dropped", notes: "").cardID
        try board.discard(id)
        let entry = try #require(try board.archive().discarded.first)
        #expect(entry.countsUntil == nil)
        #expect(!entry.isCounting)
    }

    @Test func anArchivedCardStillCountsAsThroughputFor14Days() throws {
        _ = try finish("Shipped")
        clock.advance(days: 13.9)  // archived for almost a week
        #expect(try board.cards(in: .done).isEmpty)
        #expect(try board.capacity().throughput == 1)

        clock.advance(days: 1)  // finished 14.9 days ago
        #expect(try board.capacity().throughput == 0)
    }
}
