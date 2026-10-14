import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a tiered skill mix milestone.
    final class TieredSkillMixMilestoneView {
        var code: String
        var title: String
        var facility: String
        var budget: String
        var active: String
        var statusLabel: String

        init(code: String, title: String, facility: String, budget: String, active: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.facility = facility
            self.budget = budget
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toTieredSkillMixMilestoneView(_ item: TieredSkillMixMilestone) -> TieredSkillMixMilestoneView {
        return TieredSkillMixMilestoneView(
            code: item.code,
            title: item.title,
            facility: item.facility,
            budget: String(format: "%.2f", item.budget),
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredSkillMixMilestoneViews(_ items: [TieredSkillMixMilestone]) -> [TieredSkillMixMilestoneView] {
        var views: [TieredSkillMixMilestoneView] = []
        for item in items {
            views.append(toTieredSkillMixMilestoneView(item))
        }
        return views
    }

    static func sumTieredSkillMixMilestoneView(_ view: TieredSkillMixMilestoneView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedBudget
    }
}
