import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched slot checkpoint.
    final class BatchedSlotCheckpointView {
        var codeText: String
        var nameText: String
        var ceiling: String
        var threshold: String
        var expiresAtText: String
        var summaryText: String
        var category: String
        var retries: String
        var currency: String
        var statusLabel: String

        init(codeText: String, nameText: String, ceiling: String, threshold: String, expiresAtText: String, summaryText: String, category: String, retries: String, currency: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.ceiling = ceiling
            self.threshold = threshold
            self.expiresAtText = expiresAtText
            self.summaryText = summaryText
            self.category = category
            self.retries = retries
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedSlotCheckpointView(_ item: BatchedSlotCheckpoint) -> BatchedSlotCheckpointView {
        return BatchedSlotCheckpointView(
            codeText: item.code,
            nameText: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            threshold: String(format: "%.2f", item.threshold),
            expiresAtText: String(item.expiresAt),
            summaryText: item.summary,
            category: item.category,
            retries: String(item.retries),
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedSlotCheckpointViews(_ items: [BatchedSlotCheckpoint]) -> [BatchedSlotCheckpointView] {
        var views: [BatchedSlotCheckpointView] = []
        for item in items {
            views.append(toBatchedSlotCheckpointView(item))
        }
        return views
    }

    static func sumBatchedSlotCheckpointView(_ view: BatchedSlotCheckpointView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedCeiling + parsedThreshold + Double(parsedExpiresAt)
    }
}
