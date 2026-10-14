import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up score.
    final class FollowUpScoreView {
        var code: String
        var label: String
        var amount: String
        var retriesText: String
        var batchSizeText: String
        var country: String
        var bedText: String
        var statusLabel: String

        init(code: String, label: String, amount: String, retriesText: String, batchSizeText: String, country: String, bedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.amount = amount
            self.retriesText = retriesText
            self.batchSizeText = batchSizeText
            self.country = country
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpScoreView(_ item: FollowUpScore) -> FollowUpScoreView {
        return FollowUpScoreView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            amount: String(format: "%.2f", item.amount),
            retriesText: String(item.retries),
            batchSizeText: String(item.batchSize),
            country: Kit.Text.truncate(item.country, limit: 80),
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpScoreViews(_ items: [FollowUpScore]) -> [FollowUpScoreView] {
        var views: [FollowUpScoreView] = []
        for item in items {
            views.append(toFollowUpScoreView(item))
        }
        return views
    }

    static func sumFollowUpScoreView(_ view: FollowUpScoreView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedAmount + Double(parsedRetries) + Double(parsedBatchSize)
    }
}
