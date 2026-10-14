import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a overtime preference.
    final class OvertimePreferenceView {
        var codeText: String
        var titleText: String
        var costText: String
        var encounterID: String
        var pinned: String
        var graceDays: String
        var allergy: String
        var minimum: String
        var statusLabel: String

        init(codeText: String, titleText: String, costText: String, encounterID: String, pinned: String, graceDays: String, allergy: String, minimum: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.costText = costText
            self.encounterID = encounterID
            self.pinned = pinned
            self.graceDays = graceDays
            self.allergy = allergy
            self.minimum = minimum
            self.statusLabel = statusLabel
        }
    }

    static func toOvertimePreferenceView(_ item: OvertimePreference) -> OvertimePreferenceView {
        return OvertimePreferenceView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            costText: String(format: "%.2f", item.cost),
            encounterID: item.encounterID,
            pinned: "\(item.pinned)",
            graceDays: String(item.graceDays),
            allergy: item.allergy,
            minimum: String(format: "%.2f", item.minimum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOvertimePreferenceViews(_ items: [OvertimePreference]) -> [OvertimePreferenceView] {
        var views: [OvertimePreferenceView] = []
        for item in items {
            views.append(toOvertimePreferenceView(item))
        }
        return views
    }

    static func sumOvertimePreferenceView(_ view: OvertimePreferenceView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedCost + Double(parsedGraceDays) + parsedMinimum
    }
}
