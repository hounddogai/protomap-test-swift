import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled panel adjustment.
    final class ScheduledPanelAdjustmentView {
        var code: String
        var label: String
        var visible: String
        var priorityText: String
        var statusLabel: String

        init(code: String, label: String, visible: String, priorityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.visible = visible
            self.priorityText = priorityText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledPanelAdjustmentView(_ item: ScheduledPanelAdjustment) -> ScheduledPanelAdjustmentView {
        return ScheduledPanelAdjustmentView(
            code: item.code,
            label: item.label,
            visible: "\(item.visible)",
            priorityText: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledPanelAdjustmentViews(_ items: [ScheduledPanelAdjustment]) -> [ScheduledPanelAdjustmentView] {
        var views: [ScheduledPanelAdjustmentView] = []
        for item in items {
            views.append(toScheduledPanelAdjustmentView(item))
        }
        return views
    }

    static func sumScheduledPanelAdjustmentView(_ view: ScheduledPanelAdjustmentView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
