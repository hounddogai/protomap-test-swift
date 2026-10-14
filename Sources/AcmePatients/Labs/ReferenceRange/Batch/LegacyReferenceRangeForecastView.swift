import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy reference range forecast.
    final class LegacyReferenceRangeForecastView {
        var code: String
        var label: String
        var timezoneText: String
        var visible: String
        var capacity: String
        var statusLabel: String

        init(code: String, label: String, timezoneText: String, visible: String, capacity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.timezoneText = timezoneText
            self.visible = visible
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyReferenceRangeForecastView(_ item: LegacyReferenceRangeForecast) -> LegacyReferenceRangeForecastView {
        return LegacyReferenceRangeForecastView(
            code: item.code,
            label: item.label,
            timezoneText: item.timezone,
            visible: "\(item.visible)",
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyReferenceRangeForecastViews(_ items: [LegacyReferenceRangeForecast]) -> [LegacyReferenceRangeForecastView] {
        var views: [LegacyReferenceRangeForecastView] = []
        for item in items {
            views.append(toLegacyReferenceRangeForecastView(item))
        }
        return views
    }

    static func sumLegacyReferenceRangeForecastView(_ view: LegacyReferenceRangeForecastView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedCapacity)
    }
}
