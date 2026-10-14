import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a legacy proxy budget.
    final class LegacyProxyBudgetView {
        var code: String
        var title: String
        var ceilingText: String
        var reviewer: String
        var floorValueText: String
        var description: String
        var statusLabel: String

        init(code: String, title: String, ceilingText: String, reviewer: String, floorValueText: String, description: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ceilingText = ceilingText
            self.reviewer = reviewer
            self.floorValueText = floorValueText
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyProxyBudgetView(_ item: LegacyProxyBudget) -> LegacyProxyBudgetView {
        return LegacyProxyBudgetView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            ceilingText: String(format: "%.2f", item.ceiling),
            reviewer: item.reviewer,
            floorValueText: String(format: "%.2f", item.floorValue),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyProxyBudgetViews(_ items: [LegacyProxyBudget]) -> [LegacyProxyBudgetView] {
        var views: [LegacyProxyBudgetView] = []
        for item in items {
            views.append(toLegacyProxyBudgetView(item))
        }
        return views
    }

    static func sumLegacyProxyBudgetView(_ view: LegacyProxyBudgetView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedCeiling + parsedFloorValue
    }
}
