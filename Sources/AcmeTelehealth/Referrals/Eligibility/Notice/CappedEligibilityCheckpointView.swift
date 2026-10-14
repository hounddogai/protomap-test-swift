import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a capped eligibility checkpoint.
    final class CappedEligibilityCheckpointView {
        var code: String
        var title: String
        var amountText: String
        var procedureCode: String
        var batchSizeText: String
        var statusLabel: String

        init(code: String, title: String, amountText: String, procedureCode: String, batchSizeText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.amountText = amountText
            self.procedureCode = procedureCode
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedEligibilityCheckpointView(_ item: CappedEligibilityCheckpoint) -> CappedEligibilityCheckpointView {
        return CappedEligibilityCheckpointView(
            code: item.code,
            title: item.title,
            amountText: String(format: "%.2f", item.amount),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedEligibilityCheckpointViews(_ items: [CappedEligibilityCheckpoint]) -> [CappedEligibilityCheckpointView] {
        var views: [CappedEligibilityCheckpointView] = []
        for item in items {
            views.append(toCappedEligibilityCheckpointView(item))
        }
        return views
    }

    static func sumCappedEligibilityCheckpointView(_ view: CappedEligibilityCheckpointView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedAmount + Double(parsedBatchSize)
    }
}
