// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MacKanban",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MacKanban", targets: ["MacKanban"]),
        .library(name: "KanbanCore", targets: ["KanbanCore"]),
    ],
    targets: [
        .target(name: "KanbanCore"),
        .executableTarget(name: "MacKanban", dependencies: ["KanbanCore"]),
        // A Board with Cards of every age, for screenshots: see its main.swift.
        .executableTarget(name: "SampleBoard", dependencies: ["KanbanCore"]),
        .testTarget(name: "KanbanCoreTests", dependencies: ["KanbanCore"]),
    ]
)
