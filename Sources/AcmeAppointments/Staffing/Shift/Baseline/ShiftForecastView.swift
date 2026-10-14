import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a shift forecast.
    final class ShiftForecastView {
        var code: String
        var title: String
        var rate: String
        var summaryText: String
        var minimum: String
        var label: String
        var statusLabel: String

        init(code: String, title: String, rate: String, summaryText: String, minimum: String, label: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.rate = rate
            self.summaryText = summaryText
            self.minimum = minimum
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toShiftForecastView(_ item: ShiftForecast) -> ShiftForecastView {
        return ShiftForecastView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: Kit.Text.truncate(item.title, limit: 120),
            rate: String(format: "%.2f", item.rate),
            summaryText: item.summary,
            minimum: String(format: "%.2f", item.minimum),
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toShiftForecastViews(_ items: [ShiftForecast]) -> [ShiftForecastView] {
        var views: [ShiftForecastView] = []
        for item in items {
            views.append(toShiftForecastView(item))
        }
        return views
    }

    static func sumShiftForecastView(_ view: ShiftForecastView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedRate + parsedMinimum
    }
}
