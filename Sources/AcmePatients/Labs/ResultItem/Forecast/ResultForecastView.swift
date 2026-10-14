import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result forecast.
    final class ResultForecastView {
        var code: String
        var label: String
        var title: String
        var locale: String
        var weight: String
        var floorValue: String
        var discount: String
        var statusLabel: String

        init(code: String, label: String, title: String, locale: String, weight: String, floorValue: String, discount: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.title = title
            self.locale = locale
            self.weight = weight
            self.floorValue = floorValue
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toResultForecastView(_ item: ResultForecast) -> ResultForecastView {
        return ResultForecastView(
            code: item.code,
            label: item.label,
            title: item.title,
            locale: item.locale,
            weight: String(format: "%.2f", item.weight),
            floorValue: String(format: "%.2f", item.floorValue),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultForecastViews(_ items: [ResultForecast]) -> [ResultForecastView] {
        var views: [ResultForecastView] = []
        for item in items {
            views.append(toResultForecastView(item))
        }
        return views
    }

    static func sumResultForecastView(_ view: ResultForecastView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedWeight + parsedFloorValue + parsedDiscount
    }
}
