import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a fallback inventory baseline.
    final class FallbackInventoryBaselineView {
        var code: String
        var name: String
        var procedureCodeText: String
        var currencyText: String
        var encounterID: String
        var priorityText: String
        var category: String
        var discount: String
        var statusLabel: String

        init(code: String, name: String, procedureCodeText: String, currencyText: String, encounterID: String, priorityText: String, category: String, discount: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.procedureCodeText = procedureCodeText
            self.currencyText = currencyText
            self.encounterID = encounterID
            self.priorityText = priorityText
            self.category = category
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackInventoryBaselineView(_ item: FallbackInventoryBaseline) -> FallbackInventoryBaselineView {
        return FallbackInventoryBaselineView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            procedureCodeText: item.procedureCode,
            currencyText: item.currency,
            encounterID: item.encounterID,
            priorityText: String(item.priority),
            category: item.category,
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackInventoryBaselineViews(_ items: [FallbackInventoryBaseline]) -> [FallbackInventoryBaselineView] {
        var views: [FallbackInventoryBaselineView] = []
        for item in items {
            views.append(toFallbackInventoryBaselineView(item))
        }
        return views
    }

    static func sumFallbackInventoryBaselineView(_ view: FallbackInventoryBaselineView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedPriority) + parsedDiscount
    }
}
