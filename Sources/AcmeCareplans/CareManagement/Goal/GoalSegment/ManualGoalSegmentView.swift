import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a manual goal segment.
    final class ManualGoalSegmentView {
        var codeText: String
        var name: String
        var visible: String
        var title: String
        var attemptsText: String
        var statusLabel: String

        init(codeText: String, name: String, visible: String, title: String, attemptsText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.visible = visible
            self.title = title
            self.attemptsText = attemptsText
            self.statusLabel = statusLabel
        }
    }

    static func toManualGoalSegmentView(_ item: ManualGoalSegment) -> ManualGoalSegmentView {
        return ManualGoalSegmentView(
            codeText: item.code,
            name: item.name,
            visible: "\(item.visible)",
            title: item.title,
            attemptsText: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualGoalSegmentViews(_ items: [ManualGoalSegment]) -> [ManualGoalSegmentView] {
        var views: [ManualGoalSegmentView] = []
        for item in items {
            views.append(toManualGoalSegmentView(item))
        }
        return views
    }

    static func sumManualGoalSegmentView(_ view: ManualGoalSegmentView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
