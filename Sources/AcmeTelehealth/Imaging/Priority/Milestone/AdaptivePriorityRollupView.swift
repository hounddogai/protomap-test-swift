import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive priority rollup.
    final class AdaptivePriorityRollupView {
        var code: String
        var label: String
        var name: String
        var durationMinutes: String
        var encounterIDText: String
        var segmentText: String
        var floorValueText: String
        var priorityText: String
        var capacityText: String
        var statusLabel: String

        init(code: String, label: String, name: String, durationMinutes: String, encounterIDText: String, segmentText: String, floorValueText: String, priorityText: String, capacityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.name = name
            self.durationMinutes = durationMinutes
            self.encounterIDText = encounterIDText
            self.segmentText = segmentText
            self.floorValueText = floorValueText
            self.priorityText = priorityText
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptivePriorityRollupView(_ item: AdaptivePriorityRollup) -> AdaptivePriorityRollupView {
        return AdaptivePriorityRollupView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            name: item.name,
            durationMinutes: String(item.durationMinutes),
            encounterIDText: item.encounterID,
            segmentText: item.segment,
            floorValueText: String(format: "%.2f", item.floorValue),
            priorityText: String(item.priority),
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptivePriorityRollupViews(_ items: [AdaptivePriorityRollup]) -> [AdaptivePriorityRollupView] {
        var views: [AdaptivePriorityRollupView] = []
        for item in items {
            views.append(toAdaptivePriorityRollupView(item))
        }
        return views
    }

    static func sumAdaptivePriorityRollupView(_ view: AdaptivePriorityRollupView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedDurationMinutes) + parsedFloorValue + Double(parsedPriority)
    }
}
