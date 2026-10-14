import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge metric.
    final class ChargeMetricView {
        var code: String
        var title: String
        var updatedAt: String
        var description: String
        var bedText: String
        var statusLabel: String

        init(code: String, title: String, updatedAt: String, description: String, bedText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.updatedAt = updatedAt
            self.description = description
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toChargeMetricView(_ item: ChargeMetric) -> ChargeMetricView {
        return ChargeMetricView(
            code: item.code,
            title: item.title,
            updatedAt: String(item.updatedAt),
            description: Kit.Text.truncate(item.description, limit: 40),
            bedText: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeMetricViews(_ items: [ChargeMetric]) -> [ChargeMetricView] {
        var views: [ChargeMetricView] = []
        for item in items {
            views.append(toChargeMetricView(item))
        }
        return views
    }

    static func sumChargeMetricView(_ view: ChargeMetricView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedUpdatedAt)
    }
}
