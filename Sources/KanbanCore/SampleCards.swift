import Foundation

/// The Sample Cards the app can add (ADR 0005): everyday chores whose histories
/// cover every stage of aging. Their IDs share `idPrefix`, which is all that marks
/// them, so a Sample Card written by an older version is still recognised.
enum SampleCards {
    static let idPrefix = "5A3B1E00-CA4D-4000-8000-"

    struct Chore {
        let number: Int
        let title: String
        var notes = ""
        /// Days before adding; each later step must be more recent than the one before.
        let created: Double
        var started: Double?
        var finished: Double?
        var discarded: Double?

        var id: UUID { UUID(uuidString: SampleCards.idPrefix + String(format: "%012d", number))! }
    }

    private static let hour = 1.0 / 24

    /// Right after adding: Backlog from fresh to fully red, Doing from fresh to amber,
    /// and enough recent Done Cards (Throughput 6) to leave 2 free slots.
    static let chores: [Chore] = [
        Chore(number: 1, title: "Water the plants", created: 1 * hour),
        Chore(number: 2, title: "Descale the kettle", created: 6),
        Chore(number: 3, title: "Clean out the fridge", notes: "Something at the back is growing", created: 13),
        Chore(number: 4, title: "Fix the squeaky door", notes: "The hinge in the hallway", created: 25),
        Chore(number: 5, title: "Walk the dog round the lake", created: 1, started: 2 * hour),
        Chore(number: 6, title: "Sort the winter clothes", notes: "Keep, donate, bin", created: 9, started: 4),
        Chore(number: 7, title: "Buy dog food", created: 2, started: 0.5, finished: 8 * hour),
        Chore(number: 8, title: "Take out the recycling", created: 1.5, started: 1.2, finished: 1),
        Chore(number: 9, title: "Book the puppy's grooming", created: 4, started: 2.5, finished: 2),
        Chore(number: 10, title: "Change the bed sheets", created: 5, started: 4, finished: 3.5),
        Chore(number: 11, title: "Pay the electricity bill", created: 8, started: 6, finished: 5),
        Chore(number: 12, title: "Return the library books", created: 12, started: 10, finished: 9),
        Chore(number: 13, title: "Reorganise the garage", notes: "Not this year", created: 18, discarded: 10),
    ]

    static func isSample(_ id: UUID) -> Bool {
        id.uuidString.hasPrefix(idPrefix)
    }
}

extension Card {
    /// Added by the app to show how the Board works, not created by the user.
    public var isSample: Bool { SampleCards.isSample(id) }
}
