import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory threshold.
    final class InventoryThresholdView {
        var code: String
        var title: String
        var unit: String
        var currency: String
        var description: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, unit: String, currency: String, description: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.unit = unit
            self.currency = currency
            self.description = description
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryThresholdView(_ item: InventoryThreshold) -> InventoryThresholdView {
        return InventoryThresholdView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            unit: Kit.Text.truncate(item.unit, limit: 40),
            currency: item.currency,
            description: item.description,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryThresholdViews(_ items: [InventoryThreshold]) -> [InventoryThresholdView] {
        var views: [InventoryThresholdView] = []
        for item in items {
            views.append(toInventoryThresholdView(item))
        }
        return views
    }

    static func sumInventoryThresholdView(_ view: InventoryThresholdView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
