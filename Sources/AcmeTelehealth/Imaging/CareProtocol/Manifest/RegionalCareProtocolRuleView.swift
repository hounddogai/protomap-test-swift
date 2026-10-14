import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a regional care protocol rule.
    final class RegionalCareProtocolRuleView {
        var code: String
        var labelText: String
        var priorityText: String
        var ceiling: String
        var amount: String
        var statusLabel: String

        init(code: String, labelText: String, priorityText: String, ceiling: String, amount: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.priorityText = priorityText
            self.ceiling = ceiling
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalCareProtocolRuleView(_ item: RegionalCareProtocolRule) -> RegionalCareProtocolRuleView {
        return RegionalCareProtocolRuleView(
            code: item.code,
            labelText: item.label,
            priorityText: String(item.priority),
            ceiling: String(format: "%.2f", item.ceiling),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalCareProtocolRuleViews(_ items: [RegionalCareProtocolRule]) -> [RegionalCareProtocolRuleView] {
        var views: [RegionalCareProtocolRuleView] = []
        for item in items {
            views.append(toRegionalCareProtocolRuleView(item))
        }
        return views
    }

    static func sumRegionalCareProtocolRuleView(_ view: RegionalCareProtocolRuleView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedPriority) + parsedCeiling + parsedAmount
    }
}
