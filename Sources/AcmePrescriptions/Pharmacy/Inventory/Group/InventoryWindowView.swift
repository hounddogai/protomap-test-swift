import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory window.
    final class InventoryWindowView {
        var code: String
        var title: String
        var description: String
        var activeText: String
        var externalRef: String
        var payer: String
        var source: String
        var weightText: String
        var statusLabel: String

        init(code: String, title: String, description: String, activeText: String, externalRef: String, payer: String, source: String, weightText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.activeText = activeText
            self.externalRef = externalRef
            self.payer = payer
            self.source = source
            self.weightText = weightText
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryWindowView(_ item: InventoryWindow) -> InventoryWindowView {
        return InventoryWindowView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            description: item.description,
            activeText: "\(item.active)",
            externalRef: Kit.Text.truncate(item.externalRef, limit: 64),
            payer: Kit.Text.truncate(item.payer, limit: 120),
            source: Kit.Text.truncate(item.source, limit: 40),
            weightText: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryWindowViews(_ items: [InventoryWindow]) -> [InventoryWindowView] {
        var views: [InventoryWindowView] = []
        for item in items {
            views.append(toInventoryWindowView(item))
        }
        return views
    }

    static func sumInventoryWindowView(_ view: InventoryWindowView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
