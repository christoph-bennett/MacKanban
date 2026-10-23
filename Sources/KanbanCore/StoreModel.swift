import CoreData

/// The managed object model, built in code because `swift build` without Xcode
/// can't compile an `.xcdatamodeld` (ADR 0002). It follows CloudKit's rules so
/// sync can be added later: every attribute optional or defaulted, no unique
/// constraints, every relationship optional with an inverse.
///
/// Every Event field the spec names is defined up front, even where no ticket
/// writes it yet: automatic migration can't find a code-defined source model, so
/// each later schema change would need the old model kept in code.
enum StoreModel {
    nonisolated(unsafe) static let shared: NSManagedObjectModel = make()

    private static func make() -> NSManagedObjectModel {
        let card = NSEntityDescription()
        card.name = "Card"
        card.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let event = NSEntityDescription()
        event.name = "Event"
        event.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let cardEvents = NSRelationshipDescription()
        cardEvents.name = "events"
        cardEvents.destinationEntity = event
        cardEvents.isOptional = true
        cardEvents.minCount = 0
        cardEvents.maxCount = 0  // to-many
        cardEvents.deleteRule = .cascadeDeleteRule

        let eventCard = NSRelationshipDescription()
        eventCard.name = "card"
        eventCard.destinationEntity = card
        eventCard.isOptional = true  // Board Events have no Card
        eventCard.minCount = 0
        eventCard.maxCount = 1
        eventCard.deleteRule = .nullifyDeleteRule

        cardEvents.inverseRelationship = eventCard
        eventCard.inverseRelationship = cardEvents

        card.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("title", .stringAttributeType, default: ""),
            attribute("notes", .stringAttributeType, default: ""),
            cardEvents,
        ]
        event.properties = [
            attribute("kind", .stringAttributeType, default: ""),
            attribute("timestamp", .dateAttributeType),
            attribute("fromColumn", .stringAttributeType),
            attribute("toColumn", .stringAttributeType),
            attribute("triageOutcome", .stringAttributeType),
            attribute("fromNumber", .integer64AttributeType),  // WIP Limit Changed
            attribute("toNumber", .integer64AttributeType),
            attribute("capacity", .integer64AttributeType),  // Creation Blocked
            attribute("openCardCount", .integer64AttributeType),
            eventCard,
        ]

        let model = NSManagedObjectModel()
        model.entities = [card, event]
        return model
    }

    private static func attribute(_ name: String, _ type: NSAttributeType, default value: Any? = nil) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = true
        attribute.defaultValue = value
        return attribute
    }
}
