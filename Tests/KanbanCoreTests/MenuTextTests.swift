import Foundation
import Testing
@testable import KanbanCore

/// The texts in the menu bar extra's menu (spec 0006).
@MainActor
struct MenuTextTests {
    let board: Board

    init() throws {
        board = try Board(storeURL: nil)
    }

    private func menuTitle(of title: String) throws -> String {
        try board.createCard(title: title, notes: "")
        return try #require(try board.cards(in: .backlog).first { $0.title == title }).menuTitle
    }

    // MARK: The Capacity line

    @Test func theCapacityLineSaysWhatIsUsedOfWhat() {
        let capacity = Capacity(throughput: 3, aging: 0, openCards: 4)
        #expect(capacity.usageLine == "Capacity: 4 of 8 used")
    }

    @Test func theCapacityLineLeavesOutTheAgingFigure() {
        let capacity = Capacity(throughput: 12, aging: 0.83, openCards: 4)
        #expect(capacity.usageLine == "Capacity: 4 of 16 used")
    }

    @Test func theCapacityLineShowsMoreOpenCardsThanCapacity() {
        let capacity = Capacity(throughput: 2, aging: 0, openCards: 9)
        #expect(capacity.usageLine == "Capacity: 9 of 7 used")
    }

    @Test func theCapacityLineShowsCapacityAtZeroAndBelow() {
        #expect(Capacity(throughput: 0, aging: 5, openCards: 5).usageLine == "Capacity: 5 of 0 used")
        #expect(Capacity(throughput: 0, aging: 6.5, openCards: 7).usageLine == "Capacity: 7 of -2 used")
    }

    @Test func theCapacityLineShowsTheCap() {
        let capacity = Capacity(throughput: 40, aging: 0, openCards: 3)
        #expect(capacity.usageLine == "Capacity: 3 of 20 used")
    }

    // MARK: The Doing Cards

    @Test func aCardsMenuTitleStandsBehindAGuillemet() throws {
        #expect(try menuTitle(of: "Fix the build script") == "» Fix the build script")
    }

    @Test func aTitleOfFiftyCharactersStaysWhole() throws {
        let title = String(repeating: "a", count: 50)
        #expect(try menuTitle(of: title) == "» " + title)
    }

    @Test func aLongerTitleIsShortenedToFiftyEndingInTheEllipsis() throws {
        let title = String(repeating: "a", count: 51)
        #expect(try menuTitle(of: title) == "» " + String(repeating: "a", count: 49) + "…")
    }

    @Test func aTitleWithQuotationMarksGetsNoSpecialTreatment() throws {
        #expect(try menuTitle(of: "“Quoted” talk") == "» “Quoted” talk")
    }
}
