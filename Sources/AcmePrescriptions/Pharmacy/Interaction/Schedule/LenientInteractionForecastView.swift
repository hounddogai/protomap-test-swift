import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a lenient interaction forecast.
    final class LenientInteractionForecastView {
        var code: String
        var labelText: String
        var region: String
        var capacity: String
        var description: String
        var unitText: String
        var bedText: String
        var attempts: String
        var statusLabel: String

        init(code: String, labelText: String, region: String, capacity: String, description: String, unitText: String, bedText: String, attempts: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.region = region
            self.capacity = capacity
            self.description = description
            self.unitText = unitText
            self.bedText = bedText
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toLenientInteractionForecastView(_ item: LenientInteractionForecast) -> LenientInteractionForecastView {
        return LenientInteractionForecastView(
            code: item.code,
            labelText: item.label,
            region: item.region,
            capacity: String(item.capacity),
            description: Kit.Text.truncate(item.description, limit: 64),
            unitText: Kit.Text.truncate(item.unit, limit: 120),
            bedText: item.bed,
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientInteractionForecastViews(_ items: [LenientInteractionForecast]) -> [LenientInteractionForecastView] {
        var views: [LenientInteractionForecastView] = []
        for item in items {
            views.append(toLenientInteractionForecastView(item))
        }
        return views
    }

    static func sumLenientInteractionForecastView(_ view: LenientInteractionForecastView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedCapacity) + Double(parsedAttempts)
    }
}
