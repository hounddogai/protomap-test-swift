import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal estimate.
    final class GoalEstimateView {
        var code: String
        var title: String
        var graceDays: String
        var encounterID: String
        var ownerID: String
        var visible: String
        var statusLabel: String

        init(code: String, title: String, graceDays: String, encounterID: String, ownerID: String, visible: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.encounterID = encounterID
            self.ownerID = ownerID
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toGoalEstimateView(_ item: GoalEstimate) -> GoalEstimateView {
        return GoalEstimateView(
            code: item.code,
            title: item.title,
            graceDays: String(item.graceDays),
            encounterID: item.encounterID,
            ownerID: item.ownerID,
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalEstimateViews(_ items: [GoalEstimate]) -> [GoalEstimateView] {
        var views: [GoalEstimateView] = []
        for item in items {
            views.append(toGoalEstimateView(item))
        }
        return views
    }

    static func sumGoalEstimateView(_ view: GoalEstimateView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
