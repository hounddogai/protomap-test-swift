import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a manual priority entry.
    final class ManualPriorityEntryView {
        var code: String
        var label: String
        var floorValueText: String
        var ceilingText: String
        var priority: String
        var statusLabel: String

        init(code: String, label: String, floorValueText: String, ceilingText: String, priority: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.floorValueText = floorValueText
            self.ceilingText = ceilingText
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toManualPriorityEntryView(_ item: ManualPriorityEntry) -> ManualPriorityEntryView {
        return ManualPriorityEntryView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            floorValueText: String(format: "%.2f", item.floorValue),
            ceilingText: String(format: "%.2f", item.ceiling),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualPriorityEntryViews(_ items: [ManualPriorityEntry]) -> [ManualPriorityEntryView] {
        var views: [ManualPriorityEntryView] = []
        for item in items {
            views.append(toManualPriorityEntryView(item))
        }
        return views
    }

    static func sumManualPriorityEntryView(_ view: ManualPriorityEntryView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedFloorValue + parsedCeiling + Double(parsedPriority)
    }
}
