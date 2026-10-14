import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority tier.
    final class PriorityTierView {
        var code: String
        var label: String
        var cost: String
        var acuityText: String
        var category: String
        var ceiling: String
        var statusLabel: String

        init(code: String, label: String, cost: String, acuityText: String, category: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.cost = cost
            self.acuityText = acuityText
            self.category = category
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityTierView(_ item: PriorityTier) -> PriorityTierView {
        return PriorityTierView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            cost: String(format: "%.2f", item.cost),
            acuityText: String(item.acuity),
            category: item.category,
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityTierViews(_ items: [PriorityTier]) -> [PriorityTierView] {
        var views: [PriorityTierView] = []
        for item in items {
            views.append(toPriorityTierView(item))
        }
        return views
    }

    static func sumPriorityTierView(_ view: PriorityTierView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCost + Double(parsedAcuity) + parsedCeiling
    }
}
