import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional follow up rule.
    final class RegionalFollowUpRuleView {
        var code: String
        var name: String
        var cost: String
        var ratioText: String
        var currency: String
        var endsAtText: String
        var phone: String
        var payer: String
        var statusLabel: String

        init(code: String, name: String, cost: String, ratioText: String, currency: String, endsAtText: String, phone: String, payer: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.cost = cost
            self.ratioText = ratioText
            self.currency = currency
            self.endsAtText = endsAtText
            self.phone = phone
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalFollowUpRuleView(_ item: RegionalFollowUpRule) -> RegionalFollowUpRuleView {
        return RegionalFollowUpRuleView(
            code: item.code,
            name: item.name,
            cost: String(format: "%.2f", item.cost),
            ratioText: String(format: "%.2f", item.ratio),
            currency: item.currency,
            endsAtText: String(item.endsAt),
            phone: item.phone,
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalFollowUpRuleViews(_ items: [RegionalFollowUpRule]) -> [RegionalFollowUpRuleView] {
        var views: [RegionalFollowUpRuleView] = []
        for item in items {
            views.append(toRegionalFollowUpRuleView(item))
        }
        return views
    }

    static func sumRegionalFollowUpRuleView(_ view: RegionalFollowUpRuleView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedCost + parsedRatio + Double(parsedEndsAt)
    }
}
