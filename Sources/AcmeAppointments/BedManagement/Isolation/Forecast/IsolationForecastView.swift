import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation forecast.
    final class IsolationForecastView {
        var codeText: String
        var name: String
        var versionText: String
        var country: String
        var region: String
        var statusLabel: String

        init(codeText: String, name: String, versionText: String, country: String, region: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.versionText = versionText
            self.country = country
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationForecastView(_ item: IsolationForecast) -> IsolationForecastView {
        return IsolationForecastView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            versionText: String(item.version),
            country: Kit.Text.truncate(item.country, limit: 64),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationForecastViews(_ items: [IsolationForecast]) -> [IsolationForecastView] {
        var views: [IsolationForecastView] = []
        for item in items {
            views.append(toIsolationForecastView(item))
        }
        return views
    }

    static func sumIsolationForecastView(_ view: IsolationForecastView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
