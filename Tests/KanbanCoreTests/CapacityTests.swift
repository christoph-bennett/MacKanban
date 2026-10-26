import Foundation
import Testing
@testable import KanbanCore

@MainActor
struct CapacityTests {
    let clock = TestClock()
    let board: Board

    init() throws {
        let clock = clock
        board = try Board(storeURL: nil, now: { clock.now })
    }

    @Test func anEmptyBoardHasTheBaseCapacity() throws {
        let capacity = try board.capacity()

        #expect(capacity.total == 5)
        #expect(capacity.throughput == 0)
        #expect(capacity.aging == 0)
        #expect(capacity.openCards == 0)
    }

    /// Creates a Card and returns its ID.
    private func create(_ title: String) throws -> UUID {
        try board.createCard(title: title, notes: "").cardID
    }

    /// Creates a Card and takes it through Doing to Done now.
    private func finish(_ title: String) throws {
        let id = try create(title)
        try board.move(id, to: .doing)
        try board.move(id, to: .done)
    }

    @Test func throughputCountsTheCardsFinishedInTheLast14Days() throws {
        try finish("Long ago")
        clock.advance(days: 1)
        for index in 1...4 { try finish("Recent \(index)") }
        clock.advance(days: 14)  // "Long ago" was finished 15 days ago, the rest 14

        #expect(try board.capacity().throughput == 4)
    }

    /// Spec 0001's example: Urgencies 1, 0.5 and 0.4 with Throughput 2.
    @Test func agingCardsTakeCapacityAwayInProportionToTheirUrgency() throws {
        _ = try create("21 days old")  // Urgency 1
        clock.advance(days: 10.25)
        _ = try create("10.75 days old")  // Urgency 0.5
        clock.advance(days: 2.05)
        _ = try create("8.7 days old")  // Urgency 0.4
        clock.advance(days: 0.2)
        try finish("Done A")
        try finish("Done B")
        clock.advance(days: 8.5)

        let capacity = try board.capacity()
        #expect(capacity.throughput == 2)
        #expect(abs(capacity.aging - 1.9) < 0.001)
        #expect(capacity.total == 5)  // ⌊5 + 2 − 1.9⌋
        #expect(capacity.free == 2)
    }

    @Test func capacityIsCappedAt20() throws {
        for index in 1...20 { try finish("Card \(index)") }

        #expect(try board.capacity().total == 20)
    }

    @Test func capacityHasNoFloor() throws {
        for index in 1...3 { try finish("Done \(index)") }  // Capacity 8 makes room for 7 Cards
        for index in 1...7 { _ = try create("Old \(index)") }
        clock.advance(days: 30)  // 7 fully red Cards, and the Throughput has run out

        let capacity = try board.capacity()
        #expect(capacity.total == -2)
        #expect(capacity.free == -9)
    }

    @Test func aDiscardedCardCountsForNothing() throws {
        let id = try create("Dropped")
        try board.move(id, to: .doing)
        clock.advance(days: 30)
        try board.discard(id)

        let capacity = try board.capacity()
        #expect((capacity.throughput, capacity.aging, capacity.openCards) == (0, 0, 0))
    }
}
