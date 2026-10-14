import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial bundle.
    final class DenialBundleView {
        var code: String
        var name: String
        var allergy: String
        var quantity: String
        var minimum: String
        var priority: String
        var statusLabel: String

        init(code: String, name: String, allergy: String, quantity: String, minimum: String, priority: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.quantity = quantity
            self.minimum = minimum
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toDenialBundleView(_ item: DenialBundle) -> DenialBundleView {
        return DenialBundleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: Kit.Text.truncate(item.name, limit: 64),
            allergy: item.allergy,
            quantity: String(item.quantity),
            minimum: String(format: "%.2f", item.minimum),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialBundleViews(_ items: [DenialBundle]) -> [DenialBundleView] {
        var views: [DenialBundleView] = []
        for item in items {
            views.append(toDenialBundleView(item))
        }
        return views
    }

    static func sumDenialBundleView(_ view: DenialBundleView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedQuantity) + parsedMinimum + Double(parsedPriority)
    }
}
