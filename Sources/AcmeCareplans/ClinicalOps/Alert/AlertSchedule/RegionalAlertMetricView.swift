import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a regional alert metric.
    final class RegionalAlertMetricView {
        var codeText: String
        var label: String
        var priority: String
        var ratio: String
        var category: String
        var statusLabel: String

        init(codeText: String, label: String, priority: String, ratio: String, category: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.priority = priority
            self.ratio = ratio
            self.category = category
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalAlertMetricView(_ item: RegionalAlertMetric) -> RegionalAlertMetricView {
        return RegionalAlertMetricView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            priority: String(item.priority),
            ratio: String(format: "%.2f", item.ratio),
            category: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalAlertMetricViews(_ items: [RegionalAlertMetric]) -> [RegionalAlertMetricView] {
        var views: [RegionalAlertMetricView] = []
        for item in items {
            views.append(toRegionalAlertMetricView(item))
        }
        return views
    }

    static func sumRegionalAlertMetricView(_ view: RegionalAlertMetricView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return Double(parsedPriority) + parsedRatio
    }
}
