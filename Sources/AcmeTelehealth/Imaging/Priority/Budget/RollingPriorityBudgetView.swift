import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling priority budget.
    final class RollingPriorityBudgetView {
        var codeText: String
        var label: String
        var diagnosisCode: String
        var visible: String
        var score: String
        var statusLabel: String

        init(codeText: String, label: String, diagnosisCode: String, visible: String, score: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.visible = visible
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toRollingPriorityBudgetView(_ item: RollingPriorityBudget) -> RollingPriorityBudgetView {
        return RollingPriorityBudgetView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            diagnosisCode: Kit.Text.truncate(item.diagnosisCode, limit: 40),
            visible: "\(item.visible)",
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingPriorityBudgetViews(_ items: [RollingPriorityBudget]) -> [RollingPriorityBudgetView] {
        var views: [RollingPriorityBudgetView] = []
        for item in items {
            views.append(toRollingPriorityBudgetView(item))
        }
        return views
    }

    static func sumRollingPriorityBudgetView(_ view: RollingPriorityBudgetView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
