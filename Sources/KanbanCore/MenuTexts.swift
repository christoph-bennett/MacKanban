/// The texts in the menu bar extra's menu (spec 0006).
public extension Capacity {
    /// "Capacity: 4 of 16 used". Only the two numbers: the aging figure explains
    /// nothing without the rest of the formula, which the Board's gauge shows.
    var usageLine: String { "Capacity: \(openCards) of \(total) used" }
}

public extension Card {
    /// The mark that says a menu item's words are the Card's, not a command to the
    /// app. Quotation marks are the alternative, should the guillemet not hold up.
    private static let menuMark = "» "
    private static let longestMenuTitle = 50

    /// "» Fix the build script", shortened to at most 50 characters of title.
    var menuTitle: String {
        let shortened = title.count <= Self.longestMenuTitle ? title : title.prefix(Self.longestMenuTitle - 1) + "…"
        return Self.menuMark + shortened
    }
}
