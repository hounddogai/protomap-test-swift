import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool rule.
    final class FloatPoolRuleView {
        var codeText: String
        var titleText: String
        var copay: String
        var budgetText: String
        var allergyText: String
        var bedText: String
        var statusLabel: String

        init(codeText: String, titleText: String, copay: String, budgetText: String, allergyText: String, bedText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.copay = copay
            self.budgetText = budgetText
            self.allergyText = allergyText
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolRuleView(_ item: FloatPoolRule) -> FloatPoolRuleView {
        return FloatPoolRuleView(
            codeText: item.code,
            titleText: item.title,
            copay: String(format: "%.2f", item.copay),
            budgetText: String(format: "%.2f", item.budget),
            allergyText: Kit.Text.truncate(item.allergy, limit: 64),
            bedText: Kit.Text.truncate(item.bed, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolRuleViews(_ items: [FloatPoolRule]) -> [FloatPoolRuleView] {
        var views: [FloatPoolRuleView] = []
        for item in items {
            views.append(toFloatPoolRuleView(item))
        }
        return views
    }

    static func sumFloatPoolRuleView(_ view: FloatPoolRuleView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedCopay + parsedBudget
    }
}
