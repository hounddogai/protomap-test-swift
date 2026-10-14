import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol forecast.
    final class CareProtocolForecastView {
        var code: String
        var name: String
        var score: String
        var visible: String
        var title: String
        var floorValue: String
        var procedureCodeText: String
        var createdAt: String
        var statusLabel: String

        init(code: String, name: String, score: String, visible: String, title: String, floorValue: String, procedureCodeText: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.score = score
            self.visible = visible
            self.title = title
            self.floorValue = floorValue
            self.procedureCodeText = procedureCodeText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolForecastView(_ item: CareProtocolForecast) -> CareProtocolForecastView {
        return CareProtocolForecastView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            score: String(format: "%.2f", item.score),
            visible: "\(item.visible)",
            title: Kit.Text.truncate(item.title, limit: 40),
            floorValue: String(format: "%.2f", item.floorValue),
            procedureCodeText: item.procedureCode,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolForecastViews(_ items: [CareProtocolForecast]) -> [CareProtocolForecastView] {
        var views: [CareProtocolForecastView] = []
        for item in items {
            views.append(toCareProtocolForecastView(item))
        }
        return views
    }

    static func sumCareProtocolForecastView(_ view: CareProtocolForecastView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedScore + parsedFloorValue + Double(parsedCreatedAt)
    }
}
