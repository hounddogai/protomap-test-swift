import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a primary order set cycle.
    final class PrimaryOrderSetCycleView {
        var code: String
        var labelText: String
        var floorValue: String
        var ownerIDText: String
        var quantity: String
        var encounterID: String
        var ceiling: String
        var priorityText: String
        var maximumText: String
        var segmentText: String
        var durationMinutes: String
        var statusLabel: String

        init(code: String, labelText: String, floorValue: String, ownerIDText: String, quantity: String, encounterID: String, ceiling: String, priorityText: String, maximumText: String, segmentText: String, durationMinutes: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.floorValue = floorValue
            self.ownerIDText = ownerIDText
            self.quantity = quantity
            self.encounterID = encounterID
            self.ceiling = ceiling
            self.priorityText = priorityText
            self.maximumText = maximumText
            self.segmentText = segmentText
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryOrderSetCycleView(_ item: PrimaryOrderSetCycle) -> PrimaryOrderSetCycleView {
        return PrimaryOrderSetCycleView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            floorValue: String(format: "%.2f", item.floorValue),
            ownerIDText: item.ownerID,
            quantity: String(item.quantity),
            encounterID: item.encounterID,
            ceiling: String(format: "%.2f", item.ceiling),
            priorityText: String(item.priority),
            maximumText: String(format: "%.2f", item.maximum),
            segmentText: item.segment,
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryOrderSetCycleViews(_ items: [PrimaryOrderSetCycle]) -> [PrimaryOrderSetCycleView] {
        var views: [PrimaryOrderSetCycleView] = []
        for item in items {
            views.append(toPrimaryOrderSetCycleView(item))
        }
        return views
    }

    static func sumPrimaryOrderSetCycleView(_ view: PrimaryOrderSetCycleView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedFloorValue + Double(parsedQuantity) + parsedCeiling
    }
}
