import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning plan.
    final class CleaningPlanView {
        var code: String
        var title: String
        var maximum: String
        var limit: String
        var label: String
        var refills: String
        var reviewer: String
        var allergy: String
        var amountText: String
        var statusLabel: String

        init(code: String, title: String, maximum: String, limit: String, label: String, refills: String, reviewer: String, allergy: String, amountText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.limit = limit
            self.label = label
            self.refills = refills
            self.reviewer = reviewer
            self.allergy = allergy
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningPlanView(_ item: CleaningPlan) -> CleaningPlanView {
        return CleaningPlanView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            maximum: String(format: "%.2f", item.maximum),
            limit: String(item.limit),
            label: item.label,
            refills: String(item.refills),
            reviewer: item.reviewer,
            allergy: Kit.Text.truncate(item.allergy, limit: 120),
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningPlanViews(_ items: [CleaningPlan]) -> [CleaningPlanView] {
        var views: [CleaningPlanView] = []
        for item in items {
            views.append(toCleaningPlanView(item))
        }
        return views
    }

    static func sumCleaningPlanView(_ view: CleaningPlanView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedMaximum + Double(parsedLimit) + Double(parsedRefills)
    }
}
