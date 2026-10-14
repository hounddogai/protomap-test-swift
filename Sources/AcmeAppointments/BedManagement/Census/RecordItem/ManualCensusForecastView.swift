import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a manual census forecast.
    final class ManualCensusForecastView {
        var code: String
        var name: String
        var category: String
        var expiresAt: String
        var sequence: String
        var label: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, category: String, expiresAt: String, sequence: String, label: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.category = category
            self.expiresAt = expiresAt
            self.sequence = sequence
            self.label = label
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toManualCensusForecastView(_ item: ManualCensusForecast) -> ManualCensusForecastView {
        return ManualCensusForecastView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            category: item.category,
            expiresAt: String(item.expiresAt),
            sequence: String(item.sequence),
            label: item.label,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCensusForecastViews(_ items: [ManualCensusForecast]) -> [ManualCensusForecastView] {
        var views: [ManualCensusForecastView] = []
        for item in items {
            views.append(toManualCensusForecastView(item))
        }
        return views
    }

    static func sumManualCensusForecastView(_ view: ManualCensusForecastView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedExpiresAt) + Double(parsedSequence) + Double(parsedEndsAt)
    }
}
