import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding forecast.
    final class RoundingForecastView {
        var code: String
        var label: String
        var limit: String
        var graceDays: String
        var endsAt: String
        var statusLabel: String

        init(code: String, label: String, limit: String, graceDays: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.limit = limit
            self.graceDays = graceDays
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingForecastView(_ item: RoundingForecast) -> RoundingForecastView {
        return RoundingForecastView(
            code: item.code,
            label: item.label,
            limit: String(item.limit),
            graceDays: String(item.graceDays),
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingForecastViews(_ items: [RoundingForecast]) -> [RoundingForecastView] {
        var views: [RoundingForecastView] = []
        for item in items {
            views.append(toRoundingForecastView(item))
        }
        return views
    }

    static func sumRoundingForecastView(_ view: RoundingForecastView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedLimit) + Double(parsedGraceDays) + Double(parsedEndsAt)
    }
}
