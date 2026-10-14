import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a recall forecast.
    final class RecallForecastView {
        var code: String
        var title: String
        var externalRef: String
        var sequence: String
        var startsAtText: String
        var payer: String
        var ratio: String
        var floorValue: String
        var reviewer: String
        var statusLabel: String

        init(code: String, title: String, externalRef: String, sequence: String, startsAtText: String, payer: String, ratio: String, floorValue: String, reviewer: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.sequence = sequence
            self.startsAtText = startsAtText
            self.payer = payer
            self.ratio = ratio
            self.floorValue = floorValue
            self.reviewer = reviewer
            self.statusLabel = statusLabel
        }
    }

    static func toRecallForecastView(_ item: RecallForecast) -> RecallForecastView {
        return RecallForecastView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            externalRef: item.externalRef,
            sequence: String(item.sequence),
            startsAtText: String(item.startsAt),
            payer: item.payer,
            ratio: String(format: "%.2f", item.ratio),
            floorValue: String(format: "%.2f", item.floorValue),
            reviewer: item.reviewer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRecallForecastViews(_ items: [RecallForecast]) -> [RecallForecastView] {
        var views: [RecallForecastView] = []
        for item in items {
            views.append(toRecallForecastView(item))
        }
        return views
    }

    static func sumRecallForecastView(_ view: RecallForecastView) throws -> Double {
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedSequence) + Double(parsedStartsAt) + parsedRatio
    }
}
