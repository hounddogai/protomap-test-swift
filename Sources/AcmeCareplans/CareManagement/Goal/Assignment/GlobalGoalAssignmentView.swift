import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global goal assignment.
    final class GlobalGoalAssignmentView {
        var code: String
        var label: String
        var title: String
        var thresholdText: String
        var timezone: String
        var capacity: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, label: String, title: String, thresholdText: String, timezone: String, capacity: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.title = title
            self.thresholdText = thresholdText
            self.timezone = timezone
            self.capacity = capacity
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalGoalAssignmentView(_ item: GlobalGoalAssignment) -> GlobalGoalAssignmentView {
        return GlobalGoalAssignmentView(
            code: item.code,
            label: item.label,
            title: item.title,
            thresholdText: String(format: "%.2f", item.threshold),
            timezone: Kit.Text.truncate(item.timezone, limit: 64),
            capacity: String(item.capacity),
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalGoalAssignmentViews(_ items: [GlobalGoalAssignment]) -> [GlobalGoalAssignmentView] {
        var views: [GlobalGoalAssignmentView] = []
        for item in items {
            views.append(toGlobalGoalAssignmentView(item))
        }
        return views
    }

    static func sumGlobalGoalAssignmentView(_ view: GlobalGoalAssignmentView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedThreshold + Double(parsedCapacity)
    }
}
