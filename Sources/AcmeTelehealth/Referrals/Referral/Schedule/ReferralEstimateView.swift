import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral estimate.
    final class ReferralEstimateView {
        var code: String
        var nameText: String
        var discount: String
        var priority: String
        var endsAt: String
        var statusLabel: String

        init(code: String, nameText: String, discount: String, priority: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.discount = discount
            self.priority = priority
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toReferralEstimateView(_ item: ReferralEstimate) -> ReferralEstimateView {
        return ReferralEstimateView(
            code: item.code,
            nameText: item.name,
            discount: String(format: "%.2f", item.discount),
            priority: String(item.priority),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralEstimateViews(_ items: [ReferralEstimate]) -> [ReferralEstimateView] {
        var views: [ReferralEstimateView] = []
        for item in items {
            views.append(toReferralEstimateView(item))
        }
        return views
    }

    static func sumReferralEstimateView(_ view: ReferralEstimateView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedDiscount + Double(parsedPriority) + Double(parsedEndsAt)
    }
}
