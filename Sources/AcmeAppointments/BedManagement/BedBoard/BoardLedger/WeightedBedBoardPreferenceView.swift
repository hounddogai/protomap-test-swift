import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a weighted bed board preference.
    final class WeightedBedBoardPreferenceView {
        var code: String
        var title: String
        var costText: String
        var active: String
        var score: String
        var batchSize: String
        var pinned: String
        var floorValueText: String
        var statusLabel: String

        init(code: String, title: String, costText: String, active: String, score: String, batchSize: String, pinned: String, floorValueText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.costText = costText
            self.active = active
            self.score = score
            self.batchSize = batchSize
            self.pinned = pinned
            self.floorValueText = floorValueText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedBedBoardPreferenceView(_ item: WeightedBedBoardPreference) -> WeightedBedBoardPreferenceView {
        return WeightedBedBoardPreferenceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            costText: String(format: "%.2f", item.cost),
            active: "\(item.active)",
            score: String(format: "%.2f", item.score),
            batchSize: String(item.batchSize),
            pinned: "\(item.pinned)",
            floorValueText: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedBedBoardPreferenceViews(_ items: [WeightedBedBoardPreference]) -> [WeightedBedBoardPreferenceView] {
        var views: [WeightedBedBoardPreferenceView] = []
        for item in items {
            views.append(toWeightedBedBoardPreferenceView(item))
        }
        return views
    }

    static func sumWeightedBedBoardPreferenceView(_ view: WeightedBedBoardPreferenceView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return parsedCost + parsedScore + Double(parsedBatchSize)
    }
}
