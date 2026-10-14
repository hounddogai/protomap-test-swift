import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory forecast.
    final class InventoryForecastView {
        var code: String
        var labelText: String
        var pinnedText: String
        var checksumText: String
        var name: String
        var score: String
        var statusLabel: String

        init(code: String, labelText: String, pinnedText: String, checksumText: String, name: String, score: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.pinnedText = pinnedText
            self.checksumText = checksumText
            self.name = name
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryForecastView(_ item: InventoryForecast) -> InventoryForecastView {
        return InventoryForecastView(
            code: item.code,
            labelText: item.label,
            pinnedText: "\(item.pinned)",
            checksumText: item.checksum,
            name: Kit.Text.truncate(item.name, limit: 80),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryForecastViews(_ items: [InventoryForecast]) -> [InventoryForecastView] {
        var views: [InventoryForecastView] = []
        for item in items {
            views.append(toInventoryForecastView(item))
        }
        return views
    }

    static func sumInventoryForecastView(_ view: InventoryForecastView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
