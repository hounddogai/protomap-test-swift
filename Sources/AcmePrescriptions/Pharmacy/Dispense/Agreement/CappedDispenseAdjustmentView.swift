import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a capped dispense adjustment.
    final class CappedDispenseAdjustmentView {
        var code: String
        var title: String
        var floorValue: String
        var cost: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, title: String, floorValue: String, cost: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.cost = cost
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toCappedDispenseAdjustmentView(_ item: CappedDispenseAdjustment) -> CappedDispenseAdjustmentView {
        return CappedDispenseAdjustmentView(
            code: item.code,
            title: item.title,
            floorValue: String(format: "%.2f", item.floorValue),
            cost: String(format: "%.2f", item.cost),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedDispenseAdjustmentViews(_ items: [CappedDispenseAdjustment]) -> [CappedDispenseAdjustmentView] {
        var views: [CappedDispenseAdjustmentView] = []
        for item in items {
            views.append(toCappedDispenseAdjustmentView(item))
        }
        return views
    }

    static func sumCappedDispenseAdjustmentView(_ view: CappedDispenseAdjustmentView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedFloorValue + parsedCost + Double(parsedUpdatedAt)
    }
}
