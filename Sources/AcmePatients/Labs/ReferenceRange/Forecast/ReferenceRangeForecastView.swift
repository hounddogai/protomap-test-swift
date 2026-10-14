import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range forecast.
    final class ReferenceRangeForecastView {
        var code: String
        var title: String
        var minimum: String
        var amountText: String
        var startsAtText: String
        var retries: String
        var segmentText: String
        var region: String
        var quantity: String
        var statusLabel: String

        init(code: String, title: String, minimum: String, amountText: String, startsAtText: String, retries: String, segmentText: String, region: String, quantity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.amountText = amountText
            self.startsAtText = startsAtText
            self.retries = retries
            self.segmentText = segmentText
            self.region = region
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeForecastView(_ item: ReferenceRangeForecast) -> ReferenceRangeForecastView {
        return ReferenceRangeForecastView(
            code: item.code,
            title: item.title,
            minimum: String(format: "%.2f", item.minimum),
            amountText: String(format: "%.2f", item.amount),
            startsAtText: String(item.startsAt),
            retries: String(item.retries),
            segmentText: item.segment,
            region: item.region,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeForecastViews(_ items: [ReferenceRangeForecast]) -> [ReferenceRangeForecastView] {
        var views: [ReferenceRangeForecastView] = []
        for item in items {
            views.append(toReferenceRangeForecastView(item))
        }
        return views
    }

    static func sumReferenceRangeForecastView(_ view: ReferenceRangeForecastView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return parsedMinimum + parsedAmount + Double(parsedStartsAt)
    }
}
