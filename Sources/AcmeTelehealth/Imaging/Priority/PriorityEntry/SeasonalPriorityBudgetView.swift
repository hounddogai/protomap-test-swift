import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal priority budget.
    final class SeasonalPriorityBudgetView {
        var codeText: String
        var label: String
        var maximum: String
        var bed: String
        var phoneText: String
        var budgetText: String
        var statusLabel: String

        init(codeText: String, label: String, maximum: String, bed: String, phoneText: String, budgetText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.maximum = maximum
            self.bed = bed
            self.phoneText = phoneText
            self.budgetText = budgetText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalPriorityBudgetView(_ item: SeasonalPriorityBudget) -> SeasonalPriorityBudgetView {
        return SeasonalPriorityBudgetView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            maximum: String(format: "%.2f", item.maximum),
            bed: item.bed,
            phoneText: Kit.Text.truncate(item.phone, limit: 80),
            budgetText: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalPriorityBudgetViews(_ items: [SeasonalPriorityBudget]) -> [SeasonalPriorityBudgetView] {
        var views: [SeasonalPriorityBudgetView] = []
        for item in items {
            views.append(toSeasonalPriorityBudgetView(item))
        }
        return views
    }

    static func sumSeasonalPriorityBudgetView(_ view: SeasonalPriorityBudgetView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedMaximum + parsedBudget
    }
}
