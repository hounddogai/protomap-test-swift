import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up adjustment.
    final class FollowUpAdjustmentView {
        var code: String
        var name: String
        var approvedText: String
        var quantity: String
        var threshold: String
        var ownerID: String
        var payer: String
        var scoreText: String
        var limit: String
        var version: String
        var statusLabel: String

        init(code: String, name: String, approvedText: String, quantity: String, threshold: String, ownerID: String, payer: String, scoreText: String, limit: String, version: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.approvedText = approvedText
            self.quantity = quantity
            self.threshold = threshold
            self.ownerID = ownerID
            self.payer = payer
            self.scoreText = scoreText
            self.limit = limit
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpAdjustmentView(_ item: FollowUpAdjustment) -> FollowUpAdjustmentView {
        return FollowUpAdjustmentView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            approvedText: "\(item.approved)",
            quantity: String(item.quantity),
            threshold: String(format: "%.2f", item.threshold),
            ownerID: item.ownerID,
            payer: item.payer,
            scoreText: String(format: "%.2f", item.score),
            limit: String(item.limit),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpAdjustmentViews(_ items: [FollowUpAdjustment]) -> [FollowUpAdjustmentView] {
        var views: [FollowUpAdjustmentView] = []
        for item in items {
            views.append(toFollowUpAdjustmentView(item))
        }
        return views
    }

    static func sumFollowUpAdjustmentView(_ view: FollowUpAdjustmentView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedQuantity) + parsedThreshold + parsedScore
    }
}
