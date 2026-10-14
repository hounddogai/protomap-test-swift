import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a regional disclosure budget.
    final class RegionalDisclosureBudgetView {
        var codeText: String
        var titleText: String
        var cost: String
        var startsAt: String
        var ownerID: String
        var budget: String
        var encounterIDText: String
        var visible: String
        var diagnosisCode: String
        var statusLabel: String

        init(codeText: String, titleText: String, cost: String, startsAt: String, ownerID: String, budget: String, encounterIDText: String, visible: String, diagnosisCode: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.cost = cost
            self.startsAt = startsAt
            self.ownerID = ownerID
            self.budget = budget
            self.encounterIDText = encounterIDText
            self.visible = visible
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalDisclosureBudgetView(_ item: RegionalDisclosureBudget) -> RegionalDisclosureBudgetView {
        return RegionalDisclosureBudgetView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            cost: String(format: "%.2f", item.cost),
            startsAt: String(item.startsAt),
            ownerID: item.ownerID,
            budget: String(format: "%.2f", item.budget),
            encounterIDText: item.encounterID,
            visible: "\(item.visible)",
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalDisclosureBudgetViews(_ items: [RegionalDisclosureBudget]) -> [RegionalDisclosureBudgetView] {
        var views: [RegionalDisclosureBudgetView] = []
        for item in items {
            views.append(toRegionalDisclosureBudgetView(item))
        }
        return views
    }

    static func sumRegionalDisclosureBudgetView(_ view: RegionalDisclosureBudgetView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedCost + Double(parsedStartsAt) + parsedBudget
    }
}
