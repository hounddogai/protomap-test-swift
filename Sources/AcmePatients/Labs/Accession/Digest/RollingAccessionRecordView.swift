import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling accession record.
    final class RollingAccessionRecordView {
        var code: String
        var nameText: String
        var batchSize: String
        var quantity: String
        var approved: String
        var budget: String
        var endsAt: String
        var scoreText: String
        var regionText: String
        var statusLabel: String

        init(code: String, nameText: String, batchSize: String, quantity: String, approved: String, budget: String, endsAt: String, scoreText: String, regionText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.batchSize = batchSize
            self.quantity = quantity
            self.approved = approved
            self.budget = budget
            self.endsAt = endsAt
            self.scoreText = scoreText
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAccessionRecordView(_ item: RollingAccessionRecord) -> RollingAccessionRecordView {
        return RollingAccessionRecordView(
            code: item.code,
            nameText: item.name,
            batchSize: String(item.batchSize),
            quantity: String(item.quantity),
            approved: "\(item.approved)",
            budget: String(format: "%.2f", item.budget),
            endsAt: String(item.endsAt),
            scoreText: String(format: "%.2f", item.score),
            regionText: Kit.Text.truncate(item.region, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAccessionRecordViews(_ items: [RollingAccessionRecord]) -> [RollingAccessionRecordView] {
        var views: [RollingAccessionRecordView] = []
        for item in items {
            views.append(toRollingAccessionRecordView(item))
        }
        return views
    }

    static func sumRollingAccessionRecordView(_ view: RollingAccessionRecordView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedQuantity) + parsedBudget
    }
}
