import Foundation
import Testing
@testable import KanbanCore

/// The hover text that explains a Card's colour (MVP 20): its age, and how fast
/// its Column turns red compared with the other.
@MainActor
struct UrgencyExplanationTests {
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

    private func explanation(_ id: UUID, in column: Column) throws -> String? {
        try #require(try board.cards(in: column).first { $0.id == id }).urgencyExplanation(in: column)
    }

    @Test func aDoingCardSaysHowLongItsBeenInDoingAndHowFastEachColumnTurnsRed() throws {
        let id = try create("Report")
        try board.move(id, to: .doing)
        clock.advance(days: 6 + 1.0 / 24)  // whole days, rounded down like the age label

        #expect(try explanation(id, in: .doing) == "6 days in Doing. Cards in Doing turn fully red after 7 days, in Backlog after 21.")
    }

    @Test func aBacklogCardSaysHowOldItIs() throws {
        let id = try create("Idea")
        clock.advance(days: 8 + 1.0 / 24)

        #expect(try explanation(id, in: .backlog) == "8 days old. Cards in Backlog turn fully red after 21 days, in Doing after 7.")
    }

    @Test func oneDayIsSingular() throws {
        let id = try create("Idea")
        clock.advance(days: 1 + 1.0 / 24)

        #expect(try explanation(id, in: .backlog) == "1 day old. Cards in Backlog turn fully red after 21 days, in Doing after 7.")
    }

    @Test(arguments: [(5.0, "5 hours"), (1.0, "1 hour"), (23.9, "23 hours")])
    func underADayItSaysHours(hours: Double, age: String) throws {
        let id = try create("Started")
        try board.move(id, to: .doing)
        clock.advance(days: hours / 24 + 1.0 / 86_400)  // a second past, rounded down like the age label

        #expect(try explanation(id, in: .doing) == "\(age) in Doing. Cards in Doing turn fully red after 7 days, in Backlog after 21.")
    }

    @Test func underAnHourItSaysLessThanAnHour() throws {
        let id = try create("Fresh")
        let started = try create("Just started")
        try board.move(started, to: .doing)
        clock.advance(days: 30.0 / 1_440)  // 30 minutes

        #expect(try explanation(id, in: .backlog) == "Less than an hour old. Cards in Backlog turn fully red after 21 days, in Doing after 7.")
        #expect(try explanation(started, in: .doing) == "Less than an hour in Doing. Cards in Doing turn fully red after 7 days, in Backlog after 21.")
    }

    @Test func aDoneCardHasNone() throws {
        let id = try create("Shipped")
        try board.move(id, to: .doing)
        try board.move(id, to: .done)
        clock.advance(days: 2)

        #expect(try explanation(id, in: .done) == nil)
    }
}
