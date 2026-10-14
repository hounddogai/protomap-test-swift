import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift entry.
    final class ShiftEntryView {
        var code: String
        var name: String
        var encounterID: String
        var minimum: String
        var category: String
        var statusLabel: String

        init(code: String, name: String, encounterID: String, minimum: String, category: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.minimum = minimum
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toShiftEntryView(_ item: ShiftEntry) -> ShiftEntryView {
        return ShiftEntryView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 40),
            encounterID: item.encounterID,
            minimum: String(format: "%.2f", item.minimum),
            category: Kit.Text.truncate(item.category, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftEntryViews(_ items: [ShiftEntry]) -> [ShiftEntryView] {
        var views: [ShiftEntryView] = []
        for item in items {
            views.append(toShiftEntryView(item))
        }
        return views
    }

    static func sumShiftEntryView(_ view: ShiftEntryView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
