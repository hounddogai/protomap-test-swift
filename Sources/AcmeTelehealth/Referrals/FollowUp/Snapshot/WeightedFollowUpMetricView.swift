import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted follow up metric.
    final class WeightedFollowUpMetricView {
        var codeText: String
        var titleText: String
        var startsAt: String
        var retriesText: String
        var checksum: String
        var regionText: String
        var batchSizeText: String
        var statusLabel: String

        init(codeText: String, titleText: String, startsAt: String, retriesText: String, checksum: String, regionText: String, batchSizeText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.startsAt = startsAt
            self.retriesText = retriesText
            self.checksum = checksum
            self.regionText = regionText
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedFollowUpMetricView(_ item: WeightedFollowUpMetric) -> WeightedFollowUpMetricView {
        return WeightedFollowUpMetricView(
            codeText: item.code,
            titleText: item.title,
            startsAt: String(item.startsAt),
            retriesText: String(item.retries),
            checksum: item.checksum,
            regionText: item.region,
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedFollowUpMetricViews(_ items: [WeightedFollowUpMetric]) -> [WeightedFollowUpMetricView] {
        var views: [WeightedFollowUpMetricView] = []
        for item in items {
            views.append(toWeightedFollowUpMetricView(item))
        }
        return views
    }

    static func sumWeightedFollowUpMetricView(_ view: WeightedFollowUpMetricView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedRetries) + Double(parsedBatchSize)
    }
}
