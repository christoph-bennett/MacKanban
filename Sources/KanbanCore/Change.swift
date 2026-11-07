import Foundation

/// What one Board operation recorded, so it can be undone: the Card and the
/// event the operation appended (ADR 0002: undo deletes it), with any recorded
/// alongside it.
public struct Change: Equatable, Sendable {
    public let cardID: UUID
    /// A creation is undone by deleting the Card with its events.
    let isCreation: Bool
    /// The event's Core Data object ID, as a URL.
    let event: URL
    /// Events recorded alongside it that go with it: a Triage's Triaged event.
    var companions: [URL] = []
    /// The other Cards' changes made in the same operation (Archive All Done Cards),
    /// undone together with this one. Unlike `companions`, each is checked on its
    /// own Card when undone.
    var alongside: [Change] = []
}
