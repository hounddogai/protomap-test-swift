import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral milestone.
    final class ReferralMilestoneView {
        var codeText: String
        var name: String
        var country: String
        var unit: String
        var updatedAtText: String
        var statusLabel: String

        init(codeText: String, name: String, country: String, unit: String, updatedAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.country = country
            self.unit = unit
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toReferralMilestoneView(_ item: ReferralMilestone) -> ReferralMilestoneView {
        return ReferralMilestoneView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            country: item.country,
            unit: item.unit,
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralMilestoneViews(_ items: [ReferralMilestone]) -> [ReferralMilestoneView] {
        var views: [ReferralMilestoneView] = []
        for item in items {
            views.append(toReferralMilestoneView(item))
        }
        return views
    }

    static func sumReferralMilestoneView(_ view: ReferralMilestoneView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
