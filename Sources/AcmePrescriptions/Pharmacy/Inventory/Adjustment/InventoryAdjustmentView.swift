import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory adjustment.
    final class InventoryAdjustmentView {
        var codeText: String
        var labelText: String
        var currency: String
        var maximumText: String
        var ceiling: String
        var payer: String
        var statusLabel: String

        init(codeText: String, labelText: String, currency: String, maximumText: String, ceiling: String, payer: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.currency = currency
            self.maximumText = maximumText
            self.ceiling = ceiling
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryAdjustmentView(_ item: InventoryAdjustment) -> InventoryAdjustmentView {
        return InventoryAdjustmentView(
            codeText: item.code,
            labelText: item.label,
            currency: item.currency,
            maximumText: String(format: "%.2f", item.maximum),
            ceiling: String(format: "%.2f", item.ceiling),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryAdjustmentViews(_ items: [InventoryAdjustment]) -> [InventoryAdjustmentView] {
        var views: [InventoryAdjustmentView] = []
        for item in items {
            views.append(toInventoryAdjustmentView(item))
        }
        return views
    }

    static func sumInventoryAdjustmentView(_ view: InventoryAdjustmentView) throws -> Double {
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedMaximum + parsedCeiling
    }
}
