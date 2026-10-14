import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot batch.
    final class SlotBatchView {
        var code: String
        var labelText: String
        var floorValue: String
        var source: String
        var title: String
        var unitText: String
        var ownerID: String
        var margin: String
        var weight: String
        var quantityText: String
        var statusLabel: String

        init(code: String, labelText: String, floorValue: String, source: String, title: String, unitText: String, ownerID: String, margin: String, weight: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.floorValue = floorValue
            self.source = source
            self.title = title
            self.unitText = unitText
            self.ownerID = ownerID
            self.margin = margin
            self.weight = weight
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotBatchView(_ item: SlotBatch) -> SlotBatchView {
        return SlotBatchView(
            code: item.code,
            labelText: item.label,
            floorValue: String(format: "%.2f", item.floorValue),
            source: Kit.Text.truncate(item.source, limit: 80),
            title: item.title,
            unitText: item.unit,
            ownerID: item.ownerID,
            margin: String(format: "%.2f", item.margin),
            weight: String(format: "%.2f", item.weight),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotBatchViews(_ items: [SlotBatch]) -> [SlotBatchView] {
        var views: [SlotBatchView] = []
        for item in items {
            views.append(toSlotBatchView(item))
        }
        return views
    }

    static func sumSlotBatchView(_ view: SlotBatchView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedFloorValue + parsedMargin + parsedWeight
    }
}
