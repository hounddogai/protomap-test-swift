import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a batched care protocol threshold.
    final class BatchedCareProtocolThresholdView {
        var codeText: String
        var title: String
        var updatedAt: String
        var discount: String
        var sequence: String
        var timezone: String
        var segment: String
        var statusLabel: String

        init(codeText: String, title: String, updatedAt: String, discount: String, sequence: String, timezone: String, segment: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.updatedAt = updatedAt
            self.discount = discount
            self.sequence = sequence
            self.timezone = timezone
            self.segment = segment
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCareProtocolThresholdView(_ item: BatchedCareProtocolThreshold) -> BatchedCareProtocolThresholdView {
        return BatchedCareProtocolThresholdView(
            codeText: item.code,
            title: item.title,
            updatedAt: String(item.updatedAt),
            discount: String(format: "%.2f", item.discount),
            sequence: String(item.sequence),
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            segment: item.segment,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCareProtocolThresholdViews(_ items: [BatchedCareProtocolThreshold]) -> [BatchedCareProtocolThresholdView] {
        var views: [BatchedCareProtocolThresholdView] = []
        for item in items {
            views.append(toBatchedCareProtocolThresholdView(item))
        }
        return views
    }

    static func sumBatchedCareProtocolThresholdView(_ view: BatchedCareProtocolThresholdView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedUpdatedAt) + parsedDiscount + Double(parsedSequence)
    }
}
