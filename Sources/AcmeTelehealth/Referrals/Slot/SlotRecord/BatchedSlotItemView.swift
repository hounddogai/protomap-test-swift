import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched slot item.
    final class BatchedSlotItemView {
        var code: String
        var label: String
        var procedureCode: String
        var region: String
        var pinned: String
        var amount: String
        var statusLabel: String

        init(code: String, label: String, procedureCode: String, region: String, pinned: String, amount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.procedureCode = procedureCode
            self.region = region
            self.pinned = pinned
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedSlotItemView(_ item: BatchedSlotItem) -> BatchedSlotItemView {
        return BatchedSlotItemView(
            code: item.code,
            label: item.label,
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 80),
            region: item.region,
            pinned: "\(item.pinned)",
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedSlotItemViews(_ items: [BatchedSlotItem]) -> [BatchedSlotItemView] {
        var views: [BatchedSlotItemView] = []
        for item in items {
            views.append(toBatchedSlotItemView(item))
        }
        return views
    }

    static func sumBatchedSlotItemView(_ view: BatchedSlotItemView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
