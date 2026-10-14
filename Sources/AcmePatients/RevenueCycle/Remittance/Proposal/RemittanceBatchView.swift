import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance batch.
    final class RemittanceBatchView {
        var code: String
        var name: String
        var pinned: String
        var notes: String
        var quantity: String
        var margin: String
        var statusLabel: String

        init(code: String, name: String, pinned: String, notes: String, quantity: String, margin: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.pinned = pinned
            self.notes = notes
            self.quantity = quantity
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceBatchView(_ item: RemittanceBatch) -> RemittanceBatchView {
        return RemittanceBatchView(
            code: item.code,
            name: item.name,
            pinned: "\(item.pinned)",
            notes: item.notes,
            quantity: String(item.quantity),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceBatchViews(_ items: [RemittanceBatch]) -> [RemittanceBatchView] {
        var views: [RemittanceBatchView] = []
        for item in items {
            views.append(toRemittanceBatchView(item))
        }
        return views
    }

    static func sumRemittanceBatchView(_ view: RemittanceBatchView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedQuantity) + parsedMargin
    }
}
