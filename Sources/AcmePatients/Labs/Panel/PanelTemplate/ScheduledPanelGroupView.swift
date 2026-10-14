import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled panel group.
    final class ScheduledPanelGroupView {
        var code: String
        var title: String
        var priorityText: String
        var ward: String
        var cost: String
        var statusLabel: String

        init(code: String, title: String, priorityText: String, ward: String, cost: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.priorityText = priorityText
            self.ward = ward
            self.cost = cost
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledPanelGroupView(_ item: ScheduledPanelGroup) -> ScheduledPanelGroupView {
        return ScheduledPanelGroupView(
            code: item.code,
            title: item.title,
            priorityText: String(item.priority),
            ward: item.ward,
            cost: String(format: "%.2f", item.cost),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledPanelGroupViews(_ items: [ScheduledPanelGroup]) -> [ScheduledPanelGroupView] {
        var views: [ScheduledPanelGroupView] = []
        for item in items {
            views.append(toScheduledPanelGroupView(item))
        }
        return views
    }

    static func sumScheduledPanelGroupView(_ view: ScheduledPanelGroupView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return Double(parsedPriority) + parsedCost
    }
}
