import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a fallback inventory forecast.
    final class FallbackInventoryForecastView {
        var codeText: String
        var name: String
        var score: String
        var reviewer: String
        var patientRef: String
        var cost: String
        var archivedText: String
        var regionText: String
        var statusLabel: String

        init(codeText: String, name: String, score: String, reviewer: String, patientRef: String, cost: String, archivedText: String, regionText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.score = score
            self.reviewer = reviewer
            self.patientRef = patientRef
            self.cost = cost
            self.archivedText = archivedText
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackInventoryForecastView(_ item: FallbackInventoryForecast) -> FallbackInventoryForecastView {
        return FallbackInventoryForecastView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            name: item.name,
            score: String(format: "%.2f", item.score),
            reviewer: item.reviewer,
            patientRef: item.patientRef,
            cost: String(format: "%.2f", item.cost),
            archivedText: "\(item.archived)",
            regionText: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackInventoryForecastViews(_ items: [FallbackInventoryForecast]) -> [FallbackInventoryForecastView] {
        var views: [FallbackInventoryForecastView] = []
        for item in items {
            views.append(toFallbackInventoryForecastView(item))
        }
        return views
    }

    static func sumFallbackInventoryForecastView(_ view: FallbackInventoryForecastView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedScore + parsedCost
    }
}
