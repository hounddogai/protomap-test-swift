import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a strict goal group.
    final class StrictGoalGroupView {
        var code: String
        var name: String
        var allergy: String
        var label: String
        var visible: String
        var scoreText: String
        var statusLabel: String

        init(code: String, name: String, allergy: String, label: String, visible: String, scoreText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.allergy = allergy
            self.label = label
            self.visible = visible
            self.scoreText = scoreText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictGoalGroupView(_ item: StrictGoalGroup) -> StrictGoalGroupView {
        return StrictGoalGroupView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            allergy: item.allergy,
            label: item.label,
            visible: "\(item.visible)",
            scoreText: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictGoalGroupViews(_ items: [StrictGoalGroup]) -> [StrictGoalGroupView] {
        var views: [StrictGoalGroupView] = []
        for item in items {
            views.append(toStrictGoalGroupView(item))
        }
        return views
    }

    static func sumStrictGoalGroupView(_ view: StrictGoalGroupView) throws -> Double {
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
