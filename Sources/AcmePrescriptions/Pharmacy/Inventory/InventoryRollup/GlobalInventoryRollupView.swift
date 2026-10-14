import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a global inventory rollup.
    final class GlobalInventoryRollupView {
        var codeText: String
        var title: String
        var weight: String
        var payer: String
        var quantity: String
        var capacityText: String
        var margin: String
        var bedText: String
        var contactEmailText: String
        var unit: String
        var statusLabel: String

        init(codeText: String, title: String, weight: String, payer: String, quantity: String, capacityText: String, margin: String, bedText: String, contactEmailText: String, unit: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.weight = weight
            self.payer = payer
            self.quantity = quantity
            self.capacityText = capacityText
            self.margin = margin
            self.bedText = bedText
            self.contactEmailText = contactEmailText
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalInventoryRollupView(_ item: GlobalInventoryRollup) -> GlobalInventoryRollupView {
        return GlobalInventoryRollupView(
            codeText: item.code,
            title: item.title,
            weight: String(format: "%.2f", item.weight),
            payer: Kit.Text.truncate(item.payer, limit: 80),
            quantity: String(item.quantity),
            capacityText: String(item.capacity),
            margin: String(format: "%.2f", item.margin),
            bedText: Kit.Text.truncate(item.bed, limit: 80),
            contactEmailText: item.contactEmail,
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalInventoryRollupViews(_ items: [GlobalInventoryRollup]) -> [GlobalInventoryRollupView] {
        var views: [GlobalInventoryRollupView] = []
        for item in items {
            views.append(toGlobalInventoryRollupView(item))
        }
        return views
    }

    static func sumGlobalInventoryRollupView(_ view: GlobalInventoryRollupView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedWeight + Double(parsedQuantity) + Double(parsedCapacity)
    }
}
