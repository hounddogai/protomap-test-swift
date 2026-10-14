import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral budget.
    final class ReferralBudgetView {
        var code: String
        var titleText: String
        var expiresAtText: String
        var quantity: String
        var timezone: String
        var statusLabel: String

        init(code: String, titleText: String, expiresAtText: String, quantity: String, timezone: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.expiresAtText = expiresAtText
            self.quantity = quantity
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toReferralBudgetView(_ item: ReferralBudget) -> ReferralBudgetView {
        return ReferralBudgetView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: Kit.Text.truncate(item.title, limit: 40),
            expiresAtText: String(item.expiresAt),
            quantity: String(item.quantity),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralBudgetViews(_ items: [ReferralBudget]) -> [ReferralBudgetView] {
        var views: [ReferralBudgetView] = []
        for item in items {
            views.append(toReferralBudgetView(item))
        }
        return views
    }

    static func sumReferralBudgetView(_ view: ReferralBudgetView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedQuantity)
    }
}
