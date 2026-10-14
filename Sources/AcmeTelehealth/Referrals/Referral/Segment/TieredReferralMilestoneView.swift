import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered referral milestone.
    final class TieredReferralMilestoneView {
        var code: String
        var title: String
        var externalRef: String
        var maximum: String
        var ratio: String
        var acuity: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, externalRef: String, maximum: String, ratio: String, acuity: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.maximum = maximum
            self.ratio = ratio
            self.acuity = acuity
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toTieredReferralMilestoneView(_ item: TieredReferralMilestone) -> TieredReferralMilestoneView {
        return TieredReferralMilestoneView(
            code: item.code,
            title: item.title,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            maximum: String(format: "%.2f", item.maximum),
            ratio: String(format: "%.2f", item.ratio),
            acuity: String(item.acuity),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredReferralMilestoneViews(_ items: [TieredReferralMilestone]) -> [TieredReferralMilestoneView] {
        var views: [TieredReferralMilestoneView] = []
        for item in items {
            views.append(toTieredReferralMilestoneView(item))
        }
        return views
    }

    static func sumTieredReferralMilestoneView(_ view: TieredReferralMilestoneView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return parsedMaximum + parsedRatio + Double(parsedAcuity)
    }
}
