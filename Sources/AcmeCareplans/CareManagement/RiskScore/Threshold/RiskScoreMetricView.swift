import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score metric.
    final class RiskScoreMetricView {
        var code: String
        var name: String
        var title: String
        var segment: String
        var maximum: String
        var sourceText: String
        var statusLabel: String

        init(code: String, name: String, title: String, segment: String, maximum: String, sourceText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.title = title
            self.segment = segment
            self.maximum = maximum
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreMetricView(_ item: RiskScoreMetric) -> RiskScoreMetricView {
        return RiskScoreMetricView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 64),
            segment: item.segment,
            maximum: String(format: "%.2f", item.maximum),
            sourceText: Kit.Text.truncate(item.source, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreMetricViews(_ items: [RiskScoreMetric]) -> [RiskScoreMetricView] {
        var views: [RiskScoreMetricView] = []
        for item in items {
            views.append(toRiskScoreMetricView(item))
        }
        return views
    }

    static func sumRiskScoreMetricView(_ view: RiskScoreMetricView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
