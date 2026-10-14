import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted referral segment.
    final class WeightedReferralSegmentView {
        var code: String
        var title: String
        var endsAtText: String
        var approved: String
        var descriptionText: String
        var revision: String
        var discount: String
        var quantity: String
        var statusLabel: String

        init(code: String, title: String, endsAtText: String, approved: String, descriptionText: String, revision: String, discount: String, quantity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.endsAtText = endsAtText
            self.approved = approved
            self.descriptionText = descriptionText
            self.revision = revision
            self.discount = discount
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedReferralSegmentView(_ item: WeightedReferralSegment) -> WeightedReferralSegmentView {
        return WeightedReferralSegmentView(
            code: item.code,
            title: item.title,
            endsAtText: String(item.endsAt),
            approved: "\(item.approved)",
            descriptionText: Kit.Text.truncate(item.description, limit: 40),
            revision: String(item.revision),
            discount: String(format: "%.2f", item.discount),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedReferralSegmentViews(_ items: [WeightedReferralSegment]) -> [WeightedReferralSegmentView] {
        var views: [WeightedReferralSegmentView] = []
        for item in items {
            views.append(toWeightedReferralSegmentView(item))
        }
        return views
    }

    static func sumWeightedReferralSegmentView(_ view: WeightedReferralSegmentView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedRevision) + parsedDiscount
    }
}
