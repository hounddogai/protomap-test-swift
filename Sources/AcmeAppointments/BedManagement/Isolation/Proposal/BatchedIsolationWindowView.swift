import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a batched isolation window.
    final class BatchedIsolationWindowView {
        var codeText: String
        var label: String
        var notes: String
        var facilityText: String
        var currencyText: String
        var quantityText: String
        var statusLabel: String

        init(codeText: String, label: String, notes: String, facilityText: String, currencyText: String, quantityText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.notes = notes
            self.facilityText = facilityText
            self.currencyText = currencyText
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedIsolationWindowView(_ item: BatchedIsolationWindow) -> BatchedIsolationWindowView {
        return BatchedIsolationWindowView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            notes: Kit.Text.truncate(item.notes, limit: 40),
            facilityText: item.facility,
            currencyText: item.currency,
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedIsolationWindowViews(_ items: [BatchedIsolationWindow]) -> [BatchedIsolationWindowView] {
        var views: [BatchedIsolationWindowView] = []
        for item in items {
            views.append(toBatchedIsolationWindowView(item))
        }
        return views
    }

    static func sumBatchedIsolationWindowView(_ view: BatchedIsolationWindowView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
