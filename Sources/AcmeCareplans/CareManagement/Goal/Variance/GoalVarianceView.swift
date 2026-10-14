import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal variance.
    final class GoalVarianceView {
        var codeText: String
        var label: String
        var createdAt: String
        var channel: String
        var titleText: String
        var statusLabel: String

        init(codeText: String, label: String, createdAt: String, channel: String, titleText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.createdAt = createdAt
            self.channel = channel
            self.titleText = titleText
            self.statusLabel = statusLabel
        }
    }

    static func toGoalVarianceView(_ item: GoalVariance) -> GoalVarianceView {
        return GoalVarianceView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            createdAt: String(item.createdAt),
            channel: item.channel,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalVarianceViews(_ items: [GoalVariance]) -> [GoalVarianceView] {
        var views: [GoalVarianceView] = []
        for item in items {
            views.append(toGoalVarianceView(item))
        }
        return views
    }

    static func sumGoalVarianceView(_ view: GoalVarianceView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedCreatedAt)
    }
}
