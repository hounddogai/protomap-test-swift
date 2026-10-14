import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a care protocol metric.
    final class CareProtocolMetricView {
        var code: String
        var name: String
        var bed: String
        var batchSize: String
        var graceDays: String
        var threshold: String
        var region: String
        var maximum: String
        var locale: String
        var retries: String
        var statusLabel: String

        init(code: String, name: String, bed: String, batchSize: String, graceDays: String, threshold: String, region: String, maximum: String, locale: String, retries: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.bed = bed
            self.batchSize = batchSize
            self.graceDays = graceDays
            self.threshold = threshold
            self.region = region
            self.maximum = maximum
            self.locale = locale
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toCareProtocolMetricView(_ item: CareProtocolMetric) -> CareProtocolMetricView {
        return CareProtocolMetricView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            bed: Kit.Text.truncate(item.bed, limit: 64),
            batchSize: String(item.batchSize),
            graceDays: String(item.graceDays),
            threshold: String(format: "%.2f", item.threshold),
            region: item.region,
            maximum: String(format: "%.2f", item.maximum),
            locale: item.locale,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareProtocolMetricViews(_ items: [CareProtocolMetric]) -> [CareProtocolMetricView] {
        var views: [CareProtocolMetricView] = []
        for item in items {
            views.append(toCareProtocolMetricView(item))
        }
        return views
    }

    static func sumCareProtocolMetricView(_ view: CareProtocolMetricView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedGraceDays) + parsedThreshold
    }
}
