import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a seasonal acuity plan budget.
    final class SeasonalAcuityPlanBudgetView {
        var code: String
        var name: String
        var acuityText: String
        var updatedAt: String
        var threshold: String
        var specialty: String
        var reviewer: String
        var statusLabel: String

        init(code: String, name: String, acuityText: String, updatedAt: String, threshold: String, specialty: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.acuityText = acuityText
            self.updatedAt = updatedAt
            self.threshold = threshold
            self.specialty = specialty
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalAcuityPlanBudgetView(_ item: SeasonalAcuityPlanBudget) -> SeasonalAcuityPlanBudgetView {
        return SeasonalAcuityPlanBudgetView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            acuityText: String(item.acuity),
            updatedAt: String(item.updatedAt),
            threshold: String(format: "%.2f", item.threshold),
            specialty: item.specialty,
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalAcuityPlanBudgetViews(_ items: [SeasonalAcuityPlanBudget]) -> [SeasonalAcuityPlanBudgetView] {
        var views: [SeasonalAcuityPlanBudgetView] = []
        for item in items {
            views.append(toSeasonalAcuityPlanBudgetView(item))
        }
        return views
    }

    static func sumSeasonalAcuityPlanBudgetView(_ view: SeasonalAcuityPlanBudgetView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedAcuity) + Double(parsedUpdatedAt) + parsedThreshold
    }
}
