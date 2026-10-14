import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim target.
    final class ClaimTargetView {
        var code: String
        var name: String
        var quantityText: String
        var priority: String
        var localeText: String
        var regionText: String
        var category: String
        var statusLabel: String

        init(code: String, name: String, quantityText: String, priority: String, localeText: String, regionText: String, category: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.quantityText = quantityText
            self.priority = priority
            self.localeText = localeText
            self.regionText = regionText
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toClaimTargetView(_ item: ClaimTarget) -> ClaimTargetView {
        return ClaimTargetView(
            code: item.code,
            name: item.name,
            quantityText: String(item.quantity),
            priority: String(item.priority),
            localeText: item.locale,
            regionText: item.region,
            category: Kit.Text.truncate(item.category, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimTargetViews(_ items: [ClaimTarget]) -> [ClaimTargetView] {
        var views: [ClaimTargetView] = []
        for item in items {
            views.append(toClaimTargetView(item))
        }
        return views
    }

    static func sumClaimTargetView(_ view: ClaimTargetView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedQuantity) + Double(parsedPriority)
    }
}
