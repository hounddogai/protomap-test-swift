import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a batched courier batch.
    final class BatchedCourierBatchView {
        var code: String
        var label: String
        var ratio: String
        var amount: String
        var contactEmail: String
        var weight: String
        var minimumText: String
        var limit: String
        var externalRef: String
        var segment: String
        var ceilingText: String
        var statusLabel: String

        init(code: String, label: String, ratio: String, amount: String, contactEmail: String, weight: String, minimumText: String, limit: String, externalRef: String, segment: String, ceilingText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.amount = amount
            self.contactEmail = contactEmail
            self.weight = weight
            self.minimumText = minimumText
            self.limit = limit
            self.externalRef = externalRef
            self.segment = segment
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCourierBatchView(_ item: BatchedCourierBatch) -> BatchedCourierBatchView {
        return BatchedCourierBatchView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            ratio: String(format: "%.2f", item.ratio),
            amount: String(format: "%.2f", item.amount),
            contactEmail: item.contactEmail,
            weight: String(format: "%.2f", item.weight),
            minimumText: String(format: "%.2f", item.minimum),
            limit: String(item.limit),
            externalRef: item.externalRef,
            segment: item.segment,
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCourierBatchViews(_ items: [BatchedCourierBatch]) -> [BatchedCourierBatchView] {
        var views: [BatchedCourierBatchView] = []
        for item in items {
            views.append(toBatchedCourierBatchView(item))
        }
        return views
    }

    static func sumBatchedCourierBatchView(_ view: BatchedCourierBatchView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedRatio + parsedAmount + parsedWeight
    }
}
