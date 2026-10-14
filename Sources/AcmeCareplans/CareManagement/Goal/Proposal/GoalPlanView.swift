import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal plan.
    final class GoalPlanView {
        var code: String
        var name: String
        var capacityText: String
        var reviewer: String
        var visitMinutesText: String
        var statusLabel: String

        init(code: String, name: String, capacityText: String, reviewer: String, visitMinutesText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.capacityText = capacityText
            self.reviewer = reviewer
            self.visitMinutesText = visitMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toGoalPlanView(_ item: GoalPlan) -> GoalPlanView {
        return GoalPlanView(
            code: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            capacityText: String(item.capacity),
            reviewer: item.reviewer,
            visitMinutesText: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalPlanViews(_ items: [GoalPlan]) -> [GoalPlanView] {
        var views: [GoalPlanView] = []
        for item in items {
            views.append(toGoalPlanView(item))
        }
        return views
    }

    static func sumGoalPlanView(_ view: GoalPlanView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedCapacity) + Double(parsedVisitMinutes)
    }
}
