import Foundation
import Testing
@testable import KanbanCore

/// Sending a Done Card to the Archive before the Archive Delay is up (spec 0003, ADR 0007).
@MainActor
struct ArchiveByHandTests {
    let clock = TestClock()
    let board: Board

    init() throws {
        let clock = clock
        board = try Board(storeURL: nil, now: { clock.now })
    }

    /// Creates a Card and takes it through Doing to Done over a day.
    private func finish(_ title: String) throws -> (id: UUID, toDone: Change) {
        let id = try board.createCard(title: title, notes: "").cardID
        clock.advance(days: 0.5)
        try board.move(id, to: .doing)
        clock.advance(days: 0.5)
        return (id, try board.move(id, to: .done))
    }

    @Test func anArchivedDoneCardLeavesTheBoardAndCountsAsBefore() throws {
        let older = try finish("Older").id
        clock.advance(days: 0.1)
        let shipped = try finish("Shipped").id
        clock.advance(days: 0.1)
        let capacity = try board.capacity()

        try board.archiveCard(shipped)

        #expect(try board.cards(in: .done).map(\.id) == [older])
        let archived = try #require(try board.archive().first)
        #expect((archived.id, archived.outcome) == (shipped, .done))
        #expect(try board.capacity() == capacity)
    }

    @Test func archivingIsRecordedAsAnArchivedCardEvent() throws {
        let id = try finish("Shipped").id
        clock.advance(days: 0.1)
        let archivedAt = clock.now

        try board.archiveCard(id)

        let last = try #require(try board.events().last)
        #expect((last.kind, last.cardID, last.timestamp) == (.archived, id, archivedAt))
    }

    @Test func theArchiveDatesAHandArchivedCardByWhenItWasFinished() throws {
        let created = clock.now
        let id = try finish("Shipped").id
        let finished = clock.now
        clock.advance(days: 1)

        try board.archiveCard(id)

        let archived = try #require(try board.archive().first)
        #expect((archived.created, archived.ended) == (created, finished))
    }

    @Test func aHandArchivedCardStaysArchivedWhateverTheArchiveDelay() throws {
        let id = try finish("Shipped").id
        try board.archiveCard(id)

        try board.changeArchiveDelay(to: 7)
        #expect(try board.cards(in: .done).isEmpty)
        #expect(try board.archive().map(\.id) == [id])
    }

    @Test func onlyDoneCardsCanBeArchived() throws {
        let backlog = try board.createCard(title: "Waiting", notes: "").cardID
        let doing = try board.createCard(title: "Started", notes: "").cardID
        try board.move(doing, to: .doing)

        #expect(throws: BoardError.cardIsNotDone) { try board.archiveCard(backlog) }
        #expect(throws: BoardError.cardIsNotDone) { try board.archiveCard(doing) }
    }

    @Test func aCardAlreadyInTheArchiveCantBeArchivedAgain() throws {
        let byHand = try finish("By hand").id
        try board.archiveCard(byHand)
        let byDelay = try finish("By delay").id
        clock.advance(days: 3)
        let discarded = try board.createCard(title: "Dropped", notes: "").cardID
        try board.discard(discarded)

        for id in [byHand, byDelay] {
            #expect(throws: BoardError.cardIsArchived) { try board.archiveCard(id) }
        }
        #expect(throws: BoardError.cardNotFound) { try board.archiveCard(discarded) }
    }

    @Test func sampleCardsCantBeArchivedByHand() throws {
        try board.addSampleCards()
        let sample = try #require(try board.cards(in: .done).first)

        #expect(throws: BoardError.sampleCardCantBeArchived) { try board.archiveCard(sample.id) }
        #expect(try board.cards(in: .done).contains(sample))
    }

    @Test func undoingAnArchiveBringsTheCardBackToDone() throws {
        let id = try finish("Shipped").id
        let events = try board.events()
        clock.advance(days: 0.1)
        let archive = try board.archiveCard(id)
        clock.advance(days: 0.01)  // about 14 minutes

        try board.revert(archive)

        #expect(try board.cards(in: .done).map(\.id) == [id])
        #expect(try board.archive().isEmpty)
        #expect(try board.events() == events)
    }

    @Test func anArchiveCantBeUndoneAfter15Minutes() throws {
        let id = try finish("Shipped").id
        let archive = try board.archiveCard(id)
        clock.advance(days: 0.011)  // about 16 minutes

        #expect(throws: BoardError.cannotUndo) { try board.revert(archive) }
        #expect(try board.cards(in: .done).isEmpty)
    }

    @Test func anArchiveCantBeUndoneOnceTheArchiveDelayIsUpMeanwhile() throws {
        let id = try finish("Shipped").id
        clock.advance(days: 2.995)  // about 7 minutes before the 3-day delay
        let archive = try board.archiveCard(id)
        clock.advance(days: 0.007)  // 10 minutes later: within the undo window, past the delay

        #expect(throws: BoardError.archiveDelayIsUp) { try board.revert(archive) }
        #expect(try board.archive().map(\.id) == [id])
        #expect(try board.events().last?.kind == .archived)  // nothing was undone
    }

    @Test func aMoveCantBeUndoneOnceTheCardWasArchived() throws {
        let (id, toDone) = try finish("Shipped")
        try board.archiveCard(id)

        #expect(throws: BoardError.cannotUndo) { try board.revert(toDone) }
        #expect(try board.archive().map(\.id) == [id])
    }

    @Test func archivingAgainAfterAnUndoWorks() throws {
        let id = try finish("Shipped").id
        try board.revert(try board.archiveCard(id))

        try board.archiveCard(id)  // what Redo does
        #expect(try board.cards(in: .done).isEmpty)
    }

    // Archive All Done Cards

    @Test func archiveAllTakesEveryDoneCardOffTheBoard() throws {
        let first = try finish("First").id
        let second = try finish("Second").id
        let open = try board.createCard(title: "Still open", notes: "").cardID
        let capacity = try board.capacity()

        try board.archiveAllDoneCards()

        #expect(try board.cards(in: .done).isEmpty)
        #expect(Set(try board.archive().map(\.id)) == [first, second])
        #expect(try board.cards(in: .backlog).map(\.id) == [open])
        #expect(try board.capacity() == capacity)
        #expect(try board.events().suffix(2).map(\.kind) == [.archived, .archived])
    }

    @Test func archiveAllLeavesSampleCards() throws {
        try board.addSampleCards()
        let mine = try finish("Mine").id
        let samples = try board.cards(in: .done).filter { $0.id != mine }
        #expect(!samples.isEmpty)
        let eventsBefore = try board.events().count

        try board.archiveAllDoneCards()

        #expect(try board.cards(in: .done) == samples)
        #expect(try board.archive().first?.id == mine)
        #expect(try board.events().count == eventsBefore + 1)
    }

    @Test(arguments: [false, true])
    func archiveAllIsRefusedWithNothingToArchive(withSampleCards: Bool) throws {
        if withSampleCards { try board.addSampleCards() }
        #expect(try !board.hasDoneCardsToArchive())
        #expect(throws: BoardError.nothingToArchive) { try board.archiveAllDoneCards() }
    }

    @Test func oneUndoBringsBackEveryCardArchiveAllTook() throws {
        let first = try finish("First").id
        let second = try finish("Second").id
        let events = try board.events()
        let archiveAll = try board.archiveAllDoneCards()

        try board.revert(archiveAll)

        #expect(Set(try board.cards(in: .done).map(\.id)) == [first, second])
        #expect(try board.archive().isEmpty)
        #expect(try board.events() == events)
    }

    @Test func undoingArchiveAllBringsBackTheCardsStillShortOfTheDelay() throws {
        let old = try finish("Old").id
        clock.advance(days: 1.995)
        let recent = try finish("Recent").id  // a day: Old is now about 7 minutes before the 3-day delay
        let archiveAll = try board.archiveAllDoneCards()
        clock.advance(days: 0.007)  // 10 minutes later: Old is past the delay

        try board.revert(archiveAll)

        #expect(try board.cards(in: .done).map(\.id) == [recent])
        #expect(try board.archive().map(\.id) == [old])
    }

    @Test func undoingArchiveAllIsRefusedWhenNoneOfItsCardsCanComeBack() throws {
        let id = try finish("Shipped").id
        clock.advance(days: 2.995)
        let archiveAll = try board.archiveAllDoneCards()
        clock.advance(days: 0.007)

        #expect(throws: BoardError.archiveDelayIsUp) { try board.revert(archiveAll) }
        #expect(try board.archive().map(\.id) == [id])
    }

    @Test func archiveAllNamesTheNewestDoneCardFirst() throws {
        _ = try finish("Older")
        let newest = try finish("Newest").id
        #expect(try board.archiveAllDoneCards().cardID == newest)
    }

    @Test func whetherThereIsSomethingToArchiveFollowsTheArchiveDelay() throws {
        #expect(try !board.hasDoneCardsToArchive())
        _ = try finish("Shipped")
        #expect(try board.hasDoneCardsToArchive())
        clock.advance(days: 3)  // the delay took it
        #expect(try !board.hasDoneCardsToArchive())
    }

    @Test func archiveAllCanBeDoneAgainAfterAnUndo() throws {
        _ = try finish("Shipped")
        try board.revert(try board.archiveAllDoneCards())

        try board.archiveAllDoneCards()  // what Redo does
        #expect(try board.cards(in: .done).isEmpty)
    }
}
