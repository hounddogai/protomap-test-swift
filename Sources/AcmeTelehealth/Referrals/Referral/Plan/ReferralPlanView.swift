import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a referral plan.
    final class ReferralPlanView {
        var code: String
        var title: String
        var approved: String
        var revision: String
        var ownerIDText: String
        var updatedAt: String
        var graceDays: String
        var statusLabel: String

        init(code: String, title: String, approved: String, revision: String, ownerIDText: String, updatedAt: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.approved = approved
            self.revision = revision
            self.ownerIDText = ownerIDText
            self.updatedAt = updatedAt
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toReferralPlanView(_ item: ReferralPlan) -> ReferralPlanView {
        return ReferralPlanView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            approved: "\(item.approved)",
            revision: String(item.revision),
            ownerIDText: Kit.Text.truncate(item.ownerID, limit: 80),
            updatedAt: String(item.updatedAt),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferralPlanViews(_ items: [ReferralPlan]) -> [ReferralPlanView] {
        var views: [ReferralPlanView] = []
        for item in items {
            views.append(toReferralPlanView(item))
        }
        return views
    }

    static func sumReferralPlanView(_ view: ReferralPlanView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedRevision) + Double(parsedUpdatedAt) + Double(parsedGraceDays)
    }
}
