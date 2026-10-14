import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal assignment.
    final class GoalAssignmentView {
        var codeText: String
        var title: String
        var marginText: String
        var updatedAt: String
        var checksum: String
        var statusLabel: String

        init(codeText: String, title: String, marginText: String, updatedAt: String, checksum: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.marginText = marginText
            self.updatedAt = updatedAt
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toGoalAssignmentView(_ item: GoalAssignment) -> GoalAssignmentView {
        return GoalAssignmentView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            marginText: String(format: "%.2f", item.margin),
            updatedAt: String(item.updatedAt),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalAssignmentViews(_ items: [GoalAssignment]) -> [GoalAssignmentView] {
        var views: [GoalAssignmentView] = []
        for item in items {
            views.append(toGoalAssignmentView(item))
        }
        return views
    }

    static func sumGoalAssignmentView(_ view: GoalAssignmentView) throws -> Double {
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedMargin + Double(parsedUpdatedAt)
    }
}
