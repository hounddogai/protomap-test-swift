import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding metric.
    final class RoundingMetricView {
        var codeText: String
        var name: String
        var priority: String
        var version: String
        var retriesText: String
        var statusLabel: String

        init(codeText: String, name: String, priority: String, version: String, retriesText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.priority = priority
            self.version = version
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingMetricView(_ item: RoundingMetric) -> RoundingMetricView {
        return RoundingMetricView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            priority: String(item.priority),
            version: String(item.version),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingMetricViews(_ items: [RoundingMetric]) -> [RoundingMetricView] {
        var views: [RoundingMetricView] = []
        for item in items {
            views.append(toRoundingMetricView(item))
        }
        return views
    }

    static func sumRoundingMetricView(_ view: RoundingMetricView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedPriority) + Double(parsedVersion) + Double(parsedRetries)
    }
}
