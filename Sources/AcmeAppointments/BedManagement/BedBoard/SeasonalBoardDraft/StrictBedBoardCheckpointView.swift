import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a strict bed board checkpoint.
    final class StrictBedBoardCheckpointView {
        var code: String
        var name: String
        var costText: String
        var unit: String
        var currencyText: String
        var pinned: String
        var reviewer: String
        var maximum: String
        var channelText: String
        var statusLabel: String

        init(code: String, name: String, costText: String, unit: String, currencyText: String, pinned: String, reviewer: String, maximum: String, channelText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.costText = costText
            self.unit = unit
            self.currencyText = currencyText
            self.pinned = pinned
            self.reviewer = reviewer
            self.maximum = maximum
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictBedBoardCheckpointView(_ item: StrictBedBoardCheckpoint) -> StrictBedBoardCheckpointView {
        return StrictBedBoardCheckpointView(
            code: item.code,
            name: item.name,
            costText: String(format: "%.2f", item.cost),
            unit: item.unit,
            currencyText: item.currency,
            pinned: "\(item.pinned)",
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            maximum: String(format: "%.2f", item.maximum),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictBedBoardCheckpointViews(_ items: [StrictBedBoardCheckpoint]) -> [StrictBedBoardCheckpointView] {
        var views: [StrictBedBoardCheckpointView] = []
        for item in items {
            views.append(toStrictBedBoardCheckpointView(item))
        }
        return views
    }

    static func sumStrictBedBoardCheckpointView(_ view: StrictBedBoardCheckpointView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCost + parsedMaximum
    }
}
