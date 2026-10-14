import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a rolling census forecast.
    final class RollingCensusForecastView {
        var codeText: String
        var labelText: String
        var encounterID: String
        var acuityText: String
        var segment: String
        var active: String
        var country: String
        var priority: String
        var copay: String
        var summary: String
        var statusLabel: String

        init(codeText: String, labelText: String, encounterID: String, acuityText: String, segment: String, active: String, country: String, priority: String, copay: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.encounterID = encounterID
            self.acuityText = acuityText
            self.segment = segment
            self.active = active
            self.country = country
            self.priority = priority
            self.copay = copay
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toRollingCensusForecastView(_ item: RollingCensusForecast) -> RollingCensusForecastView {
        return RollingCensusForecastView(
            codeText: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            encounterID: item.encounterID,
            acuityText: String(item.acuity),
            segment: item.segment,
            active: "\(item.active)",
            country: item.country,
            priority: String(item.priority),
            copay: String(format: "%.2f", item.copay),
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingCensusForecastViews(_ items: [RollingCensusForecast]) -> [RollingCensusForecastView] {
        var views: [RollingCensusForecastView] = []
        for item in items {
            views.append(toRollingCensusForecastView(item))
        }
        return views
    }

    static func sumRollingCensusForecastView(_ view: RollingCensusForecastView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedAcuity) + Double(parsedPriority) + parsedCopay
    }
}
