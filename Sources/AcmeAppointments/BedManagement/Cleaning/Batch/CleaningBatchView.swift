import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning batch.
    final class CleaningBatchView {
        var code: String
        var label: String
        var locale: String
        var quantity: String
        var unit: String
        var statusLabel: String

        init(code: String, label: String, locale: String, quantity: String, unit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.locale = locale
            self.quantity = quantity
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningBatchView(_ item: CleaningBatch) -> CleaningBatchView {
        return CleaningBatchView(
            code: item.code,
            label: item.label,
            locale: item.locale,
            quantity: String(item.quantity),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningBatchViews(_ items: [CleaningBatch]) -> [CleaningBatchView] {
        var views: [CleaningBatchView] = []
        for item in items {
            views.append(toCleaningBatchView(item))
        }
        return views
    }

    static func sumCleaningBatchView(_ view: CleaningBatchView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
