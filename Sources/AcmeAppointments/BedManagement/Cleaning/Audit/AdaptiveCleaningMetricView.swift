import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive cleaning metric.
    final class AdaptiveCleaningMetricView {
        var code: String
        var name: String
        var version: String
        var pinned: String
        var statusLabel: String

        init(code: String, name: String, version: String, pinned: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.version = version
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCleaningMetricView(_ item: AdaptiveCleaningMetric) -> AdaptiveCleaningMetricView {
        return AdaptiveCleaningMetricView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            version: String(item.version),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCleaningMetricViews(_ items: [AdaptiveCleaningMetric]) -> [AdaptiveCleaningMetricView] {
        var views: [AdaptiveCleaningMetricView] = []
        for item in items {
            views.append(toAdaptiveCleaningMetricView(item))
        }
        return views
    }

    static func sumAdaptiveCleaningMetricView(_ view: AdaptiveCleaningMetricView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
