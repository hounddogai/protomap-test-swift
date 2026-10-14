import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility budget.
    final class EligibilityBudgetView {
        var code: String
        var name: String
        var weight: String
        var ceiling: String
        var ownerID: String
        var graceDays: String
        var statusLabel: String

        init(code: String, name: String, weight: String, ceiling: String, ownerID: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.weight = weight
            self.ceiling = ceiling
            self.ownerID = ownerID
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityBudgetView(_ item: EligibilityBudget) -> EligibilityBudgetView {
        return EligibilityBudgetView(
            code: item.code,
            name: item.name,
            weight: String(format: "%.2f", item.weight),
            ceiling: String(format: "%.2f", item.ceiling),
            ownerID: item.ownerID,
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityBudgetViews(_ items: [EligibilityBudget]) -> [EligibilityBudgetView] {
        var views: [EligibilityBudgetView] = []
        for item in items {
            views.append(toEligibilityBudgetView(item))
        }
        return views
    }

    static func sumEligibilityBudgetView(_ view: EligibilityBudgetView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedWeight + parsedCeiling + Double(parsedGraceDays)
    }
}
