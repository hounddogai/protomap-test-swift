import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a weighted skill mix milestone.
    final class WeightedSkillMixMilestoneView {
        var code: String
        var name: String
        var visible: String
        var budgetText: String
        var scoreText: String
        var statusLabel: String

        init(code: String, name: String, visible: String, budgetText: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visible = visible
            self.budgetText = budgetText
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedSkillMixMilestoneView(_ item: WeightedSkillMixMilestone) -> WeightedSkillMixMilestoneView {
        return WeightedSkillMixMilestoneView(
            code: item.code,
            name: item.name,
            visible: "\(item.visible)",
            budgetText: String(format: "%.2f", item.budget),
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedSkillMixMilestoneViews(_ items: [WeightedSkillMixMilestone]) -> [WeightedSkillMixMilestoneView] {
        var views: [WeightedSkillMixMilestoneView] = []
        for item in items {
            views.append(toWeightedSkillMixMilestoneView(item))
        }
        return views
    }

    static func sumWeightedSkillMixMilestoneView(_ view: WeightedSkillMixMilestoneView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedBudget + parsedScore
    }
}
