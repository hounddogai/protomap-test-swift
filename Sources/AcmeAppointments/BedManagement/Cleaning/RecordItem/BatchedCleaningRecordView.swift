import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched cleaning record.
    final class BatchedCleaningRecordView {
        var code: String
        var label: String
        var payer: String
        var threshold: String
        var budgetText: String
        var createdAtText: String
        var sequenceText: String
        var statusLabel: String

        init(code: String, label: String, payer: String, threshold: String, budgetText: String, createdAtText: String, sequenceText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.payer = payer
            self.threshold = threshold
            self.budgetText = budgetText
            self.createdAtText = createdAtText
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCleaningRecordView(_ item: BatchedCleaningRecord) -> BatchedCleaningRecordView {
        return BatchedCleaningRecordView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            payer: item.payer,
            threshold: String(format: "%.2f", item.threshold),
            budgetText: String(format: "%.2f", item.budget),
            createdAtText: String(item.createdAt),
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCleaningRecordViews(_ items: [BatchedCleaningRecord]) -> [BatchedCleaningRecordView] {
        var views: [BatchedCleaningRecordView] = []
        for item in items {
            views.append(toBatchedCleaningRecordView(item))
        }
        return views
    }

    static func sumBatchedCleaningRecordView(_ view: BatchedCleaningRecordView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedThreshold + parsedBudget + Double(parsedCreatedAt)
    }
}
