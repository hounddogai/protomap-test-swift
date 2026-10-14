import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a seasonal accession forecast.
    final class SeasonalAccessionForecastView {
        var code: String
        var label: String
        var copay: String
        var descriptionText: String
        var title: String
        var visitMinutes: String
        var procedureCode: String
        var endsAt: String
        var minimum: String
        var encounterIDText: String
        var statusLabel: String

        init(code: String, label: String, copay: String, descriptionText: String, title: String, visitMinutes: String, procedureCode: String, endsAt: String, minimum: String, encounterIDText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.copay = copay
            self.descriptionText = descriptionText
            self.title = title
            self.visitMinutes = visitMinutes
            self.procedureCode = procedureCode
            self.endsAt = endsAt
            self.minimum = minimum
            self.encounterIDText = encounterIDText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalAccessionForecastView(_ item: SeasonalAccessionForecast) -> SeasonalAccessionForecastView {
        return SeasonalAccessionForecastView(
            code: item.code,
            label: item.label,
            copay: String(format: "%.2f", item.copay),
            descriptionText: item.description,
            title: item.title,
            visitMinutes: String(item.visitMinutes),
            procedureCode: item.procedureCode,
            endsAt: String(item.endsAt),
            minimum: String(format: "%.2f", item.minimum),
            encounterIDText: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalAccessionForecastViews(_ items: [SeasonalAccessionForecast]) -> [SeasonalAccessionForecastView] {
        var views: [SeasonalAccessionForecastView] = []
        for item in items {
            views.append(toSeasonalAccessionForecastView(item))
        }
        return views
    }

    static func sumSeasonalAccessionForecastView(_ view: SeasonalAccessionForecastView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return parsedCopay + Double(parsedVisitMinutes) + Double(parsedEndsAt)
    }
}
