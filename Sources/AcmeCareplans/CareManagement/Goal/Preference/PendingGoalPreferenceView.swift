import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a pending goal preference.
    final class PendingGoalPreferenceView {
        var code: String
        var nameText: String
        var cost: String
        var refills: String
        var minimum: String
        var regionText: String
        var reviewerText: String
        var encounterIDText: String
        var statusLabel: String

        init(code: String, nameText: String, cost: String, refills: String, minimum: String, regionText: String, reviewerText: String, encounterIDText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.cost = cost
            self.refills = refills
            self.minimum = minimum
            self.regionText = regionText
            self.reviewerText = reviewerText
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingGoalPreferenceView(_ item: PendingGoalPreference) -> PendingGoalPreferenceView {
        return PendingGoalPreferenceView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            cost: String(format: "%.2f", item.cost),
            refills: String(item.refills),
            minimum: String(format: "%.2f", item.minimum),
            regionText: item.region,
            reviewerText: item.reviewer,
            encounterIDText: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingGoalPreferenceViews(_ items: [PendingGoalPreference]) -> [PendingGoalPreferenceView] {
        var views: [PendingGoalPreferenceView] = []
        for item in items {
            views.append(toPendingGoalPreferenceView(item))
        }
        return views
    }

    static func sumPendingGoalPreferenceView(_ view: PendingGoalPreferenceView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedCost + Double(parsedRefills) + parsedMinimum
    }
}
