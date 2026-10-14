import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rolling alert forecast.
    final class RollingAlertForecastView {
        var codeText: String
        var label: String
        var expiresAtText: String
        var reviewer: String
        var currencyText: String
        var floorValue: String
        var encounterIDText: String
        var attempts: String
        var statusLabel: String

        init(codeText: String, label: String, expiresAtText: String, reviewer: String, currencyText: String, floorValue: String, encounterIDText: String, attempts: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.expiresAtText = expiresAtText
            self.reviewer = reviewer
            self.currencyText = currencyText
            self.floorValue = floorValue
            self.encounterIDText = encounterIDText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toRollingAlertForecastView(_ item: RollingAlertForecast) -> RollingAlertForecastView {
        return RollingAlertForecastView(
            codeText: item.code,
            label: item.label,
            expiresAtText: String(item.expiresAt),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 120),
            currencyText: Kit.Text.truncate(item.currency, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            encounterIDText: item.encounterID,
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingAlertForecastViews(_ items: [RollingAlertForecast]) -> [RollingAlertForecastView] {
        var views: [RollingAlertForecastView] = []
        for item in items {
            views.append(toRollingAlertForecastView(item))
        }
        return views
    }

    static func sumRollingAlertForecastView(_ view: RollingAlertForecastView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedExpiresAt) + parsedFloorValue + Double(parsedAttempts)
    }
}
