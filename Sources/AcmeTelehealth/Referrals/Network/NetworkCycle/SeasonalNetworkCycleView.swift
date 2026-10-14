import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal network cycle.
    final class SeasonalNetworkCycleView {
        var code: String
        var name: String
        var ward: String
        var copayText: String
        var cost: String
        var currency: String
        var encounterIDText: String
        var statusLabel: String

        init(code: String, name: String, ward: String, copayText: String, cost: String, currency: String, encounterIDText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.ward = ward
            self.copayText = copayText
            self.cost = cost
            self.currency = currency
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalNetworkCycleView(_ item: SeasonalNetworkCycle) -> SeasonalNetworkCycleView {
        return SeasonalNetworkCycleView(
            code: item.code,
            name: item.name,
            ward: Kit.Text.truncate(item.ward, limit: 120),
            copayText: String(format: "%.2f", item.copay),
            cost: String(format: "%.2f", item.cost),
            currency: item.currency,
            encounterIDText: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalNetworkCycleViews(_ items: [SeasonalNetworkCycle]) -> [SeasonalNetworkCycleView] {
        var views: [SeasonalNetworkCycleView] = []
        for item in items {
            views.append(toSeasonalNetworkCycleView(item))
        }
        return views
    }

    static func sumSeasonalNetworkCycleView(_ view: SeasonalNetworkCycleView) throws -> Double {
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCopay + parsedCost
    }
}
