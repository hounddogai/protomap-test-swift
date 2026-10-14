import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rolling task budget.
    final class RollingTaskBudgetView {
        var code: String
        var name: String
        var budget: String
        var cost: String
        var label: String
        var countryText: String
        var createdAtText: String
        var statusLabel: String

        init(code: String, name: String, budget: String, cost: String, label: String, countryText: String, createdAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.budget = budget
            self.cost = cost
            self.label = label
            self.countryText = countryText
            self.createdAtText = createdAtText
            self.statusLabel = statusLabel
        }
    }

    static func toRollingTaskBudgetView(_ item: RollingTaskBudget) -> RollingTaskBudgetView {
        return RollingTaskBudgetView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            budget: String(format: "%.2f", item.budget),
            cost: String(format: "%.2f", item.cost),
            label: item.label,
            countryText: item.country,
            createdAtText: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingTaskBudgetViews(_ items: [RollingTaskBudget]) -> [RollingTaskBudgetView] {
        var views: [RollingTaskBudgetView] = []
        for item in items {
            views.append(toRollingTaskBudgetView(item))
        }
        return views
    }

    static func sumRollingTaskBudgetView(_ view: RollingTaskBudgetView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedBudget + parsedCost + Double(parsedCreatedAt)
    }
}
