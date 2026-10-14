import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a proxy forecast.
    final class ProxyForecastView {
        var codeText: String
        var name: String
        var margin: String
        var updatedAt: String
        var encounterID: String
        var ratioText: String
        var ownerIDText: String
        var statusLabel: String

        init(codeText: String, name: String, margin: String, updatedAt: String, encounterID: String, ratioText: String, ownerIDText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.margin = margin
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.ratioText = ratioText
            self.ownerIDText = ownerIDText
            self.statusLabel = statusLabel
        }
    }

    static func toProxyForecastView(_ item: ProxyForecast) -> ProxyForecastView {
        return ProxyForecastView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            margin: String(format: "%.2f", item.margin),
            updatedAt: String(item.updatedAt),
            encounterID: item.encounterID,
            ratioText: String(format: "%.2f", item.ratio),
            ownerIDText: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toProxyForecastViews(_ items: [ProxyForecast]) -> [ProxyForecastView] {
        var views: [ProxyForecastView] = []
        for item in items {
            views.append(toProxyForecastView(item))
        }
        return views
    }

    static func sumProxyForecastView(_ view: ProxyForecastView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedMargin + Double(parsedUpdatedAt) + parsedRatio
    }
}
