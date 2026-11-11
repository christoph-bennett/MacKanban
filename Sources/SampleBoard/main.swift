import Foundation
import KanbanCore

// Writes a Board with Cards of every Urgency to the SQLite file given as the
// argument, for screenshots and trying things by hand without touching the real
// Board. With --blocked, it then adds Cards until creating is blocked. Prints
// the file's absolute path; open it with (quit MacKanban first):
//   open -n --env MACKANBAN_STORE=<absolute path> ~/Applications/MacKanban.app

func fail(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(code)
}

var arguments = Array(CommandLine.arguments.dropFirst())
let replace = arguments.contains("--replace")
let blocked = arguments.contains("--blocked")
arguments.removeAll { $0 == "--replace" || $0 == "--blocked" }
guard arguments.count == 1 else { fail("usage: SampleBoard [--replace] [--blocked] <store.sqlite>", code: 2) }
let url = URL(fileURLWithPath: (arguments[0] as NSString).expandingTildeInPath).standardizedFileURL
let realStore = URL.applicationSupportDirectory.appending(components: "MacKanban").standardizedFileURL
guard !url.path.hasPrefix(realStore.path) else { fail("Refusing to write into MacKanban's own folder: \(realStore.path)") }
if FileManager.default.fileExists(atPath: url.path) {
    guard replace else { fail("\(url.path) exists. Pass --replace to overwrite it.") }
    for suffix in ["", "-shm", "-wal"] {
        try? FileManager.default.removeItem(atPath: url.path + suffix)
    }
}

nonisolated(unsafe) var now = Date().addingTimeInterval(-40 * 86_400)

@MainActor func writeSample() throws {
    // The highest WIP Limit, so the chores below can always pass through Doing.
    let board = try Board(storeURL: url, now: { now }, wipLimit: Board.wipLimits.upperBound)
    // The Board refuses to create while blocked, so this many slots are kept free
    // by finishing chores, as aging and expiring Throughput eat into Capacity.
    // Everyday errands, so screenshots read like a real Board.
    let errands = ["Pick up the dry cleaning", "Pay the parking fine", "Get the bike serviced", "Return the parcel",
                   "Buy new running shoes", "Cancel the magazine subscription", "Order new glasses", "Defrost the freezer",
                   "Send the thank-you cards", "Change the smoke alarm batteries", "Renew the car insurance",
                   "Buy a gift for Jonas", "Clean the windows", "Book a haircut", "Reply to the school newsletter",
                   "Fix the wobbly chair", "Buy stamps", "Hang the new picture", "Return the drill to Peter",
                   "Print the boarding passes", "Pay the window cleaner", "Buy light bulbs", "Mend the jacket pocket",
                   "Water the neighbours' plants", "Take the bottles back", "Buy birdseed", "Wash the car",
                   "Pick up the prescription", "Clear the gutters", "Recycle the old batteries"]
    var fillers = 0
    func keepRoom(_ slots: Int) throws {
        while try board.capacity().free < slots {
            fillers += 1
            let filler = try board.createCard(title: fillers <= errands.count ? errands[fillers - 1] : "Errand \(fillers)", notes: "").cardID
            try board.move(filler, to: .doing)
            try board.move(filler, to: .done)
        }
    }
    func advance(days: Double) throws {
        var left = days
        while left > 0 {
            now += min(left, 0.5) * 86_400
            left -= 0.5
            try keepRoom(6)
        }
    }
    func card(_ title: String, _ notes: String = "") throws -> UUID {
        try keepRoom(6)
        try board.createCard(title: title, notes: notes)
        return try board.cards(in: .backlog).first { $0.title == title }!.id
    }

    let report = try card("Renew my passport", "The photo booth at the station does the right size")
    let shipped = try card("Book the train to Hamburg")
    try advance(days: 6)
    try board.move(shipped, to: .doing)
    let tax = try card("Do the tax return", "All the receipts are in the blue folder")
    let rust = try card("Learn the ukulele", "Maybe next year")
    try advance(days: 10)
    try board.discard(rust)  // for the Archive
    let stuck = try card("Sort the holiday photos")
    try board.move(stuck, to: .doing)
    try advance(days: 5)
    try board.move(shipped, to: .done)
    let call = try card("Call the landlord", "About the heating")
    try advance(days: 7)
    let dentist = try card("Book the dentist")
    try advance(days: 8)
    let started = try card("Write the speech for Tom's wedding")
    try board.move(started, to: .doing)
    try advance(days: 2.5)
    let fresh = try card("Reply to Anna", "Before Friday")
    try advance(days: 1.4)
    let justStarted = try card("Order Mum's birthday present")
    try board.move(justStarted, to: .doing)  // neutral in Doing: under 4 hours
    _ = (report, tax, call, dentist, fresh)
    // `now` is now about 2.4 hours ago; the app reads the real clock.
    var ideas = 0
    while blocked, try board.capacity().free > 0 {
        ideas += 1
        try board.createCard(title: "Idea \(ideas)", notes: "")
    }
    print("Creation gate: \(try board.creationGate())")
}

try MainActor.assumeIsolated { try writeSample() }
print("Wrote \(url.path)")
