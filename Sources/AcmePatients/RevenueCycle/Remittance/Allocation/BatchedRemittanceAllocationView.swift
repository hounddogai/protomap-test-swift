import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched remittance allocation.
    final class BatchedRemittanceAllocationView {
        var code: String
        var label: String
        var category: String
        var payerText: String
        var visible: String
        var amountText: String
        var statusLabel: String

        init(code: String, label: String, category: String, payerText: String, visible: String, amountText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.category = category
            self.payerText = payerText
            self.visible = visible
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedRemittanceAllocationView(_ item: BatchedRemittanceAllocation) -> BatchedRemittanceAllocationView {
        return BatchedRemittanceAllocationView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            category: Kit.Text.truncate(item.category, limit: 120),
            payerText: Kit.Text.truncate(item.payer, limit: 80),
            visible: "\(item.visible)",
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedRemittanceAllocationViews(_ items: [BatchedRemittanceAllocation]) -> [BatchedRemittanceAllocationView] {
        var views: [BatchedRemittanceAllocationView] = []
        for item in items {
            views.append(toBatchedRemittanceAllocationView(item))
        }
        return views
    }

    static func sumBatchedRemittanceAllocationView(_ view: BatchedRemittanceAllocationView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
