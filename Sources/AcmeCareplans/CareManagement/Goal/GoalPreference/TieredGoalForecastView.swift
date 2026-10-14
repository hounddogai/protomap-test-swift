import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered goal forecast.
    final class TieredGoalForecastView {
        var codeText: String
        var nameText: String
        var facility: String
        var diagnosisCode: String
        var version: String
        var payer: String
        var statusLabel: String

        init(codeText: String, nameText: String, facility: String, diagnosisCode: String, version: String, payer: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.facility = facility
            self.diagnosisCode = diagnosisCode
            self.version = version
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toTieredGoalForecastView(_ item: TieredGoalForecast) -> TieredGoalForecastView {
        return TieredGoalForecastView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            facility: Kit.Text.truncate(item.facility, limit: 64),
            diagnosisCode: item.diagnosisCode,
            version: String(item.version),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredGoalForecastViews(_ items: [TieredGoalForecast]) -> [TieredGoalForecastView] {
        var views: [TieredGoalForecastView] = []
        for item in items {
            views.append(toTieredGoalForecastView(item))
        }
        return views
    }

    static func sumTieredGoalForecastView(_ view: TieredGoalForecastView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
