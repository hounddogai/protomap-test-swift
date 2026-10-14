import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling witness entry.
    final class RollingWitnessEntryView {
        var code: String
        var nameText: String
        var approved: String
        var notes: String
        var maximum: String
        var margin: String
        var statusLabel: String

        init(code: String, nameText: String, approved: String, notes: String, maximum: String, margin: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.approved = approved
            self.notes = notes
            self.maximum = maximum
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toRollingWitnessEntryView(_ item: RollingWitnessEntry) -> RollingWitnessEntryView {
        return RollingWitnessEntryView(
            code: item.code,
            nameText: item.name,
            approved: "\(item.approved)",
            notes: item.notes,
            maximum: String(format: "%.2f", item.maximum),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingWitnessEntryViews(_ items: [RollingWitnessEntry]) -> [RollingWitnessEntryView] {
        var views: [RollingWitnessEntryView] = []
        for item in items {
            views.append(toRollingWitnessEntryView(item))
        }
        return views
    }

    static func sumRollingWitnessEntryView(_ view: RollingWitnessEntryView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return parsedMaximum + parsedMargin
    }
}
