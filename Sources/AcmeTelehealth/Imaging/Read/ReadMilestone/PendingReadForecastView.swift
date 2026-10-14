import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending read forecast.
    final class PendingReadForecastView {
        var code: String
        var name: String
        var visitMinutes: String
        var active: String
        var encounterID: String
        var score: String
        var region: String
        var statusLabel: String

        init(code: String, name: String, visitMinutes: String, active: String, encounterID: String, score: String, region: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.active = active
            self.encounterID = encounterID
            self.score = score
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toPendingReadForecastView(_ item: PendingReadForecast) -> PendingReadForecastView {
        return PendingReadForecastView(
            code: item.code,
            name: item.name,
            visitMinutes: String(item.visitMinutes),
            active: "\(item.active)",
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            score: String(format: "%.2f", item.score),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingReadForecastViews(_ items: [PendingReadForecast]) -> [PendingReadForecastView] {
        var views: [PendingReadForecastView] = []
        for item in items {
            views.append(toPendingReadForecastView(item))
        }
        return views
    }

    static func sumPendingReadForecastView(_ view: PendingReadForecastView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedVisitMinutes) + parsedScore
    }
}
