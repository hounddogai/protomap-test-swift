import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral rollup.
    final class ReferralRollupView {
        var codeText: String
        var labelText: String
        var copay: String
        var locale: String
        var updatedAt: String
        var cost: String
        var archived: String
        var budget: String
        var rate: String
        var phone: String
        var statusLabel: String

        init(codeText: String, labelText: String, copay: String, locale: String, updatedAt: String, cost: String, archived: String, budget: String, rate: String, phone: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.copay = copay
            self.locale = locale
            self.updatedAt = updatedAt
            self.cost = cost
            self.archived = archived
            self.budget = budget
            self.rate = rate
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toReferralRollupView(_ item: ReferralRollup) -> ReferralRollupView {
        return ReferralRollupView(
            codeText: item.code,
            labelText: item.label,
            copay: String(format: "%.2f", item.copay),
            locale: item.locale,
            updatedAt: String(item.updatedAt),
            cost: String(format: "%.2f", item.cost),
            archived: "\(item.archived)",
            budget: String(format: "%.2f", item.budget),
            rate: String(format: "%.2f", item.rate),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralRollupViews(_ items: [ReferralRollup]) -> [ReferralRollupView] {
        var views: [ReferralRollupView] = []
        for item in items {
            views.append(toReferralRollupView(item))
        }
        return views
    }

    static func sumReferralRollupView(_ view: ReferralRollupView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCopay + Double(parsedUpdatedAt) + parsedCost
    }
}
