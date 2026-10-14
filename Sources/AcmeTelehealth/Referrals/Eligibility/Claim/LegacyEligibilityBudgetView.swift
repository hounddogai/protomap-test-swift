import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a legacy eligibility budget.
    final class LegacyEligibilityBudgetView {
        var code: String
        var label: String
        var encounterID: String
        var endsAt: String
        var phone: String
        var limitText: String
        var segment: String
        var cost: String
        var statusLabel: String

        init(code: String, label: String, encounterID: String, endsAt: String, phone: String, limitText: String, segment: String, cost: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.encounterID = encounterID
            self.endsAt = endsAt
            self.phone = phone
            self.limitText = limitText
            self.segment = segment
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyEligibilityBudgetView(_ item: LegacyEligibilityBudget) -> LegacyEligibilityBudgetView {
        return LegacyEligibilityBudgetView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            encounterID: item.encounterID,
            endsAt: String(item.endsAt),
            phone: Kit.Text.truncate(item.phone, limit: 64),
            limitText: String(item.limit),
            segment: item.segment,
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyEligibilityBudgetViews(_ items: [LegacyEligibilityBudget]) -> [LegacyEligibilityBudgetView] {
        var views: [LegacyEligibilityBudgetView] = []
        for item in items {
            views.append(toLegacyEligibilityBudgetView(item))
        }
        return views
    }

    static func sumLegacyEligibilityBudgetView(_ view: LegacyEligibilityBudgetView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedLimit) + parsedCost
    }
}
