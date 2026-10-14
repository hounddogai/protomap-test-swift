import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal preference.
    final class GoalPreferenceView {
        var code: String
        var title: String
        var description: String
        var source: String
        var floorValue: String
        var statusLabel: String

        init(code: String, title: String, description: String, source: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.description = description
            self.source = source
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toGoalPreferenceView(_ item: GoalPreference) -> GoalPreferenceView {
        return GoalPreferenceView(
            code: item.code,
            title: item.title,
            description: item.description,
            source: Kit.Text.truncate(item.source, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalPreferenceViews(_ items: [GoalPreference]) -> [GoalPreferenceView] {
        var views: [GoalPreferenceView] = []
        for item in items {
            views.append(toGoalPreferenceView(item))
        }
        return views
    }

    static func sumGoalPreferenceView(_ view: GoalPreferenceView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return parsedFloorValue
    }
}
