import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up tier.
    final class FollowUpTierView {
        var code: String
        var label: String
        var acuityText: String
        var createdAtText: String
        var costText: String
        var checksum: String
        var statusLabel: String

        init(code: String, label: String, acuityText: String, createdAtText: String, costText: String, checksum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.acuityText = acuityText
            self.createdAtText = createdAtText
            self.costText = costText
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpTierView(_ item: FollowUpTier) -> FollowUpTierView {
        return FollowUpTierView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            acuityText: String(item.acuity),
            createdAtText: String(item.createdAt),
            costText: String(format: "%.2f", item.cost),
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpTierViews(_ items: [FollowUpTier]) -> [FollowUpTierView] {
        var views: [FollowUpTierView] = []
        for item in items {
            views.append(toFollowUpTierView(item))
        }
        return views
    }

    static func sumFollowUpTierView(_ view: FollowUpTierView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedAcuity) + Double(parsedCreatedAt) + parsedCost
    }
}
