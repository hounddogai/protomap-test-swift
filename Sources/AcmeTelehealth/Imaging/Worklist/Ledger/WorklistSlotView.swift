import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist slot.
    final class WorklistSlotView {
        var codeText: String
        var name: String
        var description: String
        var capacity: String
        var cost: String
        var weightText: String
        var label: String
        var windowDays: String
        var statusLabel: String

        init(codeText: String, name: String, description: String, capacity: String, cost: String, weightText: String, label: String, windowDays: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.description = description
            self.capacity = capacity
            self.cost = cost
            self.weightText = weightText
            self.label = label
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistSlotView(_ item: WorklistSlot) -> WorklistSlotView {
        return WorklistSlotView(
            codeText: item.code,
            name: item.name,
            description: Kit.Text.truncate(item.description, limit: 120),
            capacity: String(item.capacity),
            cost: String(format: "%.2f", item.cost),
            weightText: String(format: "%.2f", item.weight),
            label: Kit.Text.truncate(item.label, limit: 80),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistSlotViews(_ items: [WorklistSlot]) -> [WorklistSlotView] {
        var views: [WorklistSlotView] = []
        for item in items {
            views.append(toWorklistSlotView(item))
        }
        return views
    }

    static func sumWorklistSlotView(_ view: WorklistSlotView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return Double(parsedCapacity) + parsedCost + parsedWeight
    }
}
