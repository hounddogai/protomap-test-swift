import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a legacy isolation forecast.
    final class LegacyIsolationForecastView {
        var code: String
        var name: String
        var encounterID: String
        var updatedAt: String
        var visible: String
        var minimum: String
        var thresholdText: String
        var weight: String
        var floorValue: String
        var cost: String
        var checksum: String
        var statusLabel: String

        init(code: String, name: String, encounterID: String, updatedAt: String, visible: String, minimum: String, thresholdText: String, weight: String, floorValue: String, cost: String, checksum: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.encounterID = encounterID
            self.updatedAt = updatedAt
            self.visible = visible
            self.minimum = minimum
            self.thresholdText = thresholdText
            self.weight = weight
            self.floorValue = floorValue
            self.cost = cost
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyIsolationForecastView(_ item: LegacyIsolationForecast) -> LegacyIsolationForecastView {
        return LegacyIsolationForecastView(
            code: item.code,
            name: item.name,
            encounterID: item.encounterID,
            updatedAt: String(item.updatedAt),
            visible: "\(item.visible)",
            minimum: String(format: "%.2f", item.minimum),
            thresholdText: String(format: "%.2f", item.threshold),
            weight: String(format: "%.2f", item.weight),
            floorValue: String(format: "%.2f", item.floorValue),
            cost: String(format: "%.2f", item.cost),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyIsolationForecastViews(_ items: [LegacyIsolationForecast]) -> [LegacyIsolationForecastView] {
        var views: [LegacyIsolationForecastView] = []
        for item in items {
            views.append(toLegacyIsolationForecastView(item))
        }
        return views
    }

    static func sumLegacyIsolationForecastView(_ view: LegacyIsolationForecastView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedUpdatedAt) + parsedMinimum + parsedThreshold
    }
}
