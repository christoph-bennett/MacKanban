import Foundation
import Testing
@testable import KanbanCore

@MainActor
struct SampleCardsTests {
    let clock = TestClock()
    let board: Board

    init() throws {
        let clock = clock
        board = try Board(storeURL: nil, now: { clock.now })
    }

    @Test func sampleCardsShowEveryStageOfAgingAndLeaveRoomToCreate() throws {
        try board.addSampleCards()

        let state = try board.state()
        let backlog = state.columns[.backlog] ?? []
        let doing = state.columns[.doing] ?? []
        #expect(backlog.contains { $0.urgency == 0 })
        #expect(backlog.contains { $0.urgency > 0 && $0.urgency < 0.5 })
        #expect(backlog.contains { $0.urgency >= 0.5 && $0.urgency < 1 })
        #expect(backlog.contains { $0.urgency == 1 })
        #expect(doing.contains { $0.urgency == 0 })
        #expect(doing.contains { $0.urgency > 0 })
        #expect(doing.count <= board.wipLimit)
        #expect(!(state.columns[.done] ?? []).isEmpty)
        #expect(state.capacity.free >= 1)
        let archive = try board.archive()
        #expect(archive.contains { $0.outcome == .discarded })
        #expect(archive.contains { $0.outcome == .done })
        let all = backlog + doing + (state.columns[.done] ?? []) + archive.map(\.card)
        #expect(all.allSatisfy { $0.isSample })
        #expect(try board.sampleCardCount() == all.count)
    }

    @Test func sampleCardsAreRefusedWhileTheBoardHasAnOpenCard() throws {
        try board.createCard(title: "My own", notes: "")

        #expect(try !board.canAddSampleCards())
        #expect(throws: BoardError.sampleCardsNeedEmptyBoard) { try board.addSampleCards() }
        #expect(try board.sampleCardCount() == 0)
    }

    @Test func sampleCardsCanBeAddedNextToFinishedCardsOfMyOwn() throws {
        try board.createCard(title: "My own", notes: "")
        let mine = try #require(try board.cards(in: .backlog).first).id
        try board.move(mine, to: .doing)
        try board.move(mine, to: .done)

        #expect(try board.canAddSampleCards())
        try board.addSampleCards()
        #expect(try board.cards(in: .done).contains { $0.id == mine })
    }

    @Test func sampleCardsCanBeAddedOnlyOnce() throws {
        try board.addSampleCards()
        for card in try board.cards(in: .backlog) + board.cards(in: .doing) { try board.discard(card.id) }

        #expect(try !board.canAddSampleCards())
        #expect(throws: BoardError.sampleCardsNeedEmptyBoard) { try board.addSampleCards() }
    }

    @Test func removingSampleCardsLeavesNoTraceAndKeepsMyCardsAndBoardEvents() throws {
        try board.addSampleCards()
        let count = try board.sampleCardCount()
        try board.changeWIPLimit(to: 4)
        try board.discard(try #require(try board.cards(in: .backlog).last).id)
        try board.createCard(title: "Added on top", notes: "")
        let mine = try #require(try board.cards(in: .backlog).first { $0.title == "Added on top" }).id

        #expect(try board.removeSampleCards() == count)

        #expect(try board.sampleCardCount() == 0)
        #expect(try board.cards(in: .backlog).map(\.id) == [mine])
        #expect(try board.cards(in: .doing).isEmpty)
        #expect(try board.cards(in: .done).isEmpty)
        #expect(try board.archive().isEmpty)
        #expect(try board.events().map(\.kind) == [.wipLimitChanged, .created])
        #expect(try board.canAddSampleCards() == false)  // my Card is open
    }

    @Test func doingSampleCardsStayWithinALowWIPLimit() throws {
        try board.changeWIPLimit(to: 1)

        try board.addSampleCards()

        #expect(try board.cards(in: .doing).count == 1)
    }

    @Test func sampleCardsCanBeMovedAndDiscardedButNotEdited() throws {
        try board.addSampleCards()
        let waiting = try #require(try board.cards(in: .backlog).first)
        let started = try #require(try board.cards(in: .doing).first)

        #expect(throws: BoardError.sampleCardIsReadOnly) { try board.edit(waiting.id, title: "Mine now", notes: "") }
        #expect(try board.cards(in: .backlog).first?.title == waiting.title)
        try board.move(started.id, to: .done)
        try board.discard(waiting.id)
        #expect(try board.cards(in: .done).first?.id == started.id)
        #expect(try board.events().suffix(2).map(\.kind) == [.moved, .discarded])
    }

    @Test func myOwnCardsAreNotSampleCards() throws {
        try board.createCard(title: "My own", notes: "")

        #expect(try board.cards(in: .backlog).allSatisfy { !$0.isSample })
        #expect(try board.sampleCardCount() == 0)
    }

    @Test func aBoardHasCardsOnceOneWasCreatedEvenAfterItLeft() throws {
        #expect(try !board.hasCards())
        try board.changeWIPLimit(to: 2)
        #expect(try !board.hasCards())  // Board Events aren't Cards

        try board.createCard(title: "Gone soon", notes: "")
        try board.discard(try #require(try board.cards(in: .backlog).first).id)

        #expect(try board.hasCards())
    }
}
