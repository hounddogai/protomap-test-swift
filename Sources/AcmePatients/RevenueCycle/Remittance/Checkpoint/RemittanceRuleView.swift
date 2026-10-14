import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance rule.
    final class RemittanceRuleView {
        var code: String
        var titleText: String
        var bed: String
        var floorValueText: String
        var budget: String
        var statusLabel: String

        init(code: String, titleText: String, bed: String, floorValueText: String, budget: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.bed = bed
            self.floorValueText = floorValueText
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceRuleView(_ item: RemittanceRule) -> RemittanceRuleView {
        return RemittanceRuleView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            bed: item.bed,
            floorValueText: String(format: "%.2f", item.floorValue),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceRuleViews(_ items: [RemittanceRule]) -> [RemittanceRuleView] {
        var views: [RemittanceRuleView] = []
        for item in items {
            views.append(toRemittanceRuleView(item))
        }
        return views
    }

    static func sumRemittanceRuleView(_ view: RemittanceRuleView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedFloorValue + parsedBudget
    }
}
