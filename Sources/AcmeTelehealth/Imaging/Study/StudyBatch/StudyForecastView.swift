import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study forecast.
    final class StudyForecastView {
        var code: String
        var label: String
        var unit: String
        var timezone: String
        var refillsText: String
        var procedureCodeText: String
        var copay: String
        var checksum: String
        var statusLabel: String

        init(code: String, label: String, unit: String, timezone: String, refillsText: String, procedureCodeText: String, copay: String, checksum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.unit = unit
            self.timezone = timezone
            self.refillsText = refillsText
            self.procedureCodeText = procedureCodeText
            self.copay = copay
            self.checksum = checksum
            self.statusLabel = statusLabel
        }
    }

    static func toStudyForecastView(_ item: StudyForecast) -> StudyForecastView {
        return StudyForecastView(
            code: item.code,
            label: item.label,
            unit: Kit.Text.truncate(item.unit, limit: 120),
            timezone: item.timezone,
            refillsText: String(item.refills),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 120),
            copay: String(format: "%.2f", item.copay),
            checksum: item.checksum,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudyForecastViews(_ items: [StudyForecast]) -> [StudyForecastView] {
        var views: [StudyForecastView] = []
        for item in items {
            views.append(toStudyForecastView(item))
        }
        return views
    }

    static func sumStudyForecastView(_ view: StudyForecastView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedRefills) + parsedCopay
    }
}
