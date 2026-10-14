import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a capped cleaning forecast.
    final class CappedCleaningForecastView {
        var code: String
        var title: String
        var acuityText: String
        var batchSize: String
        var source: String
        var margin: String
        var copay: String
        var summaryText: String
        var expiresAtText: String
        var statusLabel: String

        init(code: String, title: String, acuityText: String, batchSize: String, source: String, margin: String, copay: String, summaryText: String, expiresAtText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.acuityText = acuityText
            self.batchSize = batchSize
            self.source = source
            self.margin = margin
            self.copay = copay
            self.summaryText = summaryText
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCleaningForecastView(_ item: CappedCleaningForecast) -> CappedCleaningForecastView {
        return CappedCleaningForecastView(
            code: item.code,
            title: item.title,
            acuityText: String(item.acuity),
            batchSize: String(item.batchSize),
            source: item.source,
            margin: String(format: "%.2f", item.margin),
            copay: String(format: "%.2f", item.copay),
            summaryText: item.summary,
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCleaningForecastViews(_ items: [CappedCleaningForecast]) -> [CappedCleaningForecastView] {
        var views: [CappedCleaningForecastView] = []
        for item in items {
            views.append(toCappedCleaningForecastView(item))
        }
        return views
    }

    static func sumCappedCleaningForecastView(_ view: CappedCleaningForecastView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedAcuity) + Double(parsedBatchSize) + parsedMargin
    }
}
