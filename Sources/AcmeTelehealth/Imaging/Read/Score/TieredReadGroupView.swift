import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered read group.
    final class TieredReadGroupView {
        var code: String
        var name: String
        var batchSizeText: String
        var costText: String
        var regionText: String
        var allergy: String
        var startsAt: String
        var statusLabel: String

        init(code: String, name: String, batchSizeText: String, costText: String, regionText: String, allergy: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.batchSizeText = batchSizeText
            self.costText = costText
            self.regionText = regionText
            self.allergy = allergy
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toTieredReadGroupView(_ item: TieredReadGroup) -> TieredReadGroupView {
        return TieredReadGroupView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            batchSizeText: String(item.batchSize),
            costText: String(format: "%.2f", item.cost),
            regionText: item.region,
            allergy: item.allergy,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredReadGroupViews(_ items: [TieredReadGroup]) -> [TieredReadGroupView] {
        var views: [TieredReadGroupView] = []
        for item in items {
            views.append(toTieredReadGroupView(item))
        }
        return views
    }

    static func sumTieredReadGroupView(_ view: TieredReadGroupView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedBatchSize) + parsedCost + Double(parsedStartsAt)
    }
}
