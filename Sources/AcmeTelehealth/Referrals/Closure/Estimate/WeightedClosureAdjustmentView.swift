import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted closure adjustment.
    final class WeightedClosureAdjustmentView {
        var code: String
        var nameText: String
        var floorValue: String
        var capacityText: String
        var payer: String
        var updatedAt: String
        var country: String
        var limit: String
        var statusLabel: String

        init(code: String, nameText: String, floorValue: String, capacityText: String, payer: String, updatedAt: String, country: String, limit: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.floorValue = floorValue
            self.capacityText = capacityText
            self.payer = payer
            self.updatedAt = updatedAt
            self.country = country
            self.limit = limit
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedClosureAdjustmentView(_ item: WeightedClosureAdjustment) -> WeightedClosureAdjustmentView {
        return WeightedClosureAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            floorValue: String(format: "%.2f", item.floorValue),
            capacityText: String(item.capacity),
            payer: item.payer,
            updatedAt: String(item.updatedAt),
            country: Kit.Text.truncate(item.country, limit: 40),
            limit: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedClosureAdjustmentViews(_ items: [WeightedClosureAdjustment]) -> [WeightedClosureAdjustmentView] {
        var views: [WeightedClosureAdjustmentView] = []
        for item in items {
            views.append(toWeightedClosureAdjustmentView(item))
        }
        return views
    }

    static func sumWeightedClosureAdjustmentView(_ view: WeightedClosureAdjustmentView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedFloorValue + Double(parsedCapacity) + Double(parsedUpdatedAt)
    }
}
