import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a legacy result forecast.
    final class LegacyResultForecastView {
        var code: String
        var title: String
        var ceilingText: String
        var rateText: String
        var payer: String
        var quantity: String
        var statusLabel: String

        init(code: String, title: String, ceilingText: String, rateText: String, payer: String, quantity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ceilingText = ceilingText
            self.rateText = rateText
            self.payer = payer
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyResultForecastView(_ item: LegacyResultForecast) -> LegacyResultForecastView {
        return LegacyResultForecastView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            ceilingText: String(format: "%.2f", item.ceiling),
            rateText: String(format: "%.2f", item.rate),
            payer: Kit.Text.truncate(item.payer, limit: 80),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyResultForecastViews(_ items: [LegacyResultForecast]) -> [LegacyResultForecastView] {
        var views: [LegacyResultForecastView] = []
        for item in items {
            views.append(toLegacyResultForecastView(item))
        }
        return views
    }

    static func sumLegacyResultForecastView(_ view: LegacyResultForecastView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedCeiling + parsedRate + Double(parsedQuantity)
    }
}
