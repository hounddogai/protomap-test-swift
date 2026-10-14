import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a adaptive rounding metric.
    final class AdaptiveRoundingMetricView {
        var codeText: String
        var title: String
        var createdAt: String
        var region: String
        var minimum: String
        var ratioText: String
        var nameText: String
        var retriesText: String
        var unit: String
        var statusLabel: String

        init(codeText: String, title: String, createdAt: String, region: String, minimum: String, ratioText: String, nameText: String, retriesText: String, unit: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.createdAt = createdAt
            self.region = region
            self.minimum = minimum
            self.ratioText = ratioText
            self.nameText = nameText
            self.retriesText = retriesText
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveRoundingMetricView(_ item: AdaptiveRoundingMetric) -> AdaptiveRoundingMetricView {
        return AdaptiveRoundingMetricView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            title: Kit.Text.truncate(item.title, limit: 64),
            createdAt: String(item.createdAt),
            region: item.region,
            minimum: String(format: "%.2f", item.minimum),
            ratioText: String(format: "%.2f", item.ratio),
            nameText: item.name,
            retriesText: String(item.retries),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveRoundingMetricViews(_ items: [AdaptiveRoundingMetric]) -> [AdaptiveRoundingMetricView] {
        var views: [AdaptiveRoundingMetricView] = []
        for item in items {
            views.append(toAdaptiveRoundingMetricView(item))
        }
        return views
    }

    static func sumAdaptiveRoundingMetricView(_ view: AdaptiveRoundingMetricView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedCreatedAt) + parsedMinimum + parsedRatio
    }
}
