import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling disclosure forecast.
    final class RollingDisclosureForecastView {
        var code: String
        var titleText: String
        var pinned: String
        var procedureCodeText: String
        var capacityText: String
        var country: String
        var margin: String
        var retriesText: String
        var facility: String
        var statusLabel: String

        init(code: String, titleText: String, pinned: String, procedureCodeText: String, capacityText: String, country: String, margin: String, retriesText: String, facility: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.pinned = pinned
            self.procedureCodeText = procedureCodeText
            self.capacityText = capacityText
            self.country = country
            self.margin = margin
            self.retriesText = retriesText
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toRollingDisclosureForecastView(_ item: RollingDisclosureForecast) -> RollingDisclosureForecastView {
        return RollingDisclosureForecastView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            pinned: "\(item.pinned)",
            procedureCodeText: item.procedureCode,
            capacityText: String(item.capacity),
            country: item.country,
            margin: String(format: "%.2f", item.margin),
            retriesText: String(item.retries),
            facility: item.facility,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingDisclosureForecastViews(_ items: [RollingDisclosureForecast]) -> [RollingDisclosureForecastView] {
        var views: [RollingDisclosureForecastView] = []
        for item in items {
            views.append(toRollingDisclosureForecastView(item))
        }
        return views
    }

    static func sumRollingDisclosureForecastView(_ view: RollingDisclosureForecastView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedCapacity) + parsedMargin + Double(parsedRetries)
    }
}
