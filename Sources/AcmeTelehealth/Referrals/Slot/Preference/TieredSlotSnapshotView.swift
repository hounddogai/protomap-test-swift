import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a tiered slot snapshot.
    final class TieredSlotSnapshotView {
        var codeText: String
        var nameText: String
        var updatedAt: String
        var timezone: String
        var acuity: String
        var reviewerText: String
        var costText: String
        var country: String
        var discount: String
        var statusLabel: String

        init(codeText: String, nameText: String, updatedAt: String, timezone: String, acuity: String, reviewerText: String, costText: String, country: String, discount: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.updatedAt = updatedAt
            self.timezone = timezone
            self.acuity = acuity
            self.reviewerText = reviewerText
            self.costText = costText
            self.country = country
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toTieredSlotSnapshotView(_ item: TieredSlotSnapshot) -> TieredSlotSnapshotView {
        return TieredSlotSnapshotView(
            codeText: item.code,
            nameText: item.name,
            updatedAt: String(item.updatedAt),
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            acuity: String(item.acuity),
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 40),
            costText: String(format: "%.2f", item.cost),
            country: item.country,
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredSlotSnapshotViews(_ items: [TieredSlotSnapshot]) -> [TieredSlotSnapshotView] {
        var views: [TieredSlotSnapshotView] = []
        for item in items {
            views.append(toTieredSlotSnapshotView(item))
        }
        return views
    }

    static func sumTieredSlotSnapshotView(_ view: TieredSlotSnapshotView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedAcuity) + parsedCost
    }
}
