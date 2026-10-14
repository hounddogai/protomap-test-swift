import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a batched inventory baseline.
    final class BatchedInventoryBaselineView {
        var code: String
        var labelText: String
        var contactEmail: String
        var summary: String
        var payerText: String
        var minimum: String
        var phone: String
        var statusLabel: String

        init(code: String, labelText: String, contactEmail: String, summary: String, payerText: String, minimum: String, phone: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.contactEmail = contactEmail
            self.summary = summary
            self.payerText = payerText
            self.minimum = minimum
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedInventoryBaselineView(_ item: BatchedInventoryBaseline) -> BatchedInventoryBaselineView {
        return BatchedInventoryBaselineView(
            code: Kit.Text.truncate(item.code, limit: 40),
            labelText: item.label,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            summary: item.summary,
            payerText: item.payer,
            minimum: String(format: "%.2f", item.minimum),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedInventoryBaselineViews(_ items: [BatchedInventoryBaseline]) -> [BatchedInventoryBaselineView] {
        var views: [BatchedInventoryBaselineView] = []
        for item in items {
            views.append(toBatchedInventoryBaselineView(item))
        }
        return views
    }

    static func sumBatchedInventoryBaselineView(_ view: BatchedInventoryBaselineView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
