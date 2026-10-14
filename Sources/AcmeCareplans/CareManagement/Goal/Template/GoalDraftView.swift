import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal draft.
    final class GoalDraftView {
        var codeText: String
        var label: String
        var startsAtText: String
        var copay: String
        var pinned: String
        var priority: String
        var statusLabel: String

        init(codeText: String, label: String, startsAtText: String, copay: String, pinned: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.startsAtText = startsAtText
            self.copay = copay
            self.pinned = pinned
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toGoalDraftView(_ item: GoalDraft) -> GoalDraftView {
        return GoalDraftView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 80),
            startsAtText: String(item.startsAt),
            copay: String(format: "%.2f", item.copay),
            pinned: "\(item.pinned)",
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalDraftViews(_ items: [GoalDraft]) -> [GoalDraftView] {
        var views: [GoalDraftView] = []
        for item in items {
            views.append(toGoalDraftView(item))
        }
        return views
    }

    static func sumGoalDraftView(_ view: GoalDraftView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedStartsAt) + parsedCopay + Double(parsedPriority)
    }
}
