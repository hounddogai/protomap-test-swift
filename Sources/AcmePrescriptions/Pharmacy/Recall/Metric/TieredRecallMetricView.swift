import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a tiered recall metric.
    final class TieredRecallMetricView {
        var code: String
        var name: String
        var limitText: String
        var approved: String
        var segment: String
        var bed: String
        var statusLabel: String

        init(code: String, name: String, limitText: String, approved: String, segment: String, bed: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.limitText = limitText
            self.approved = approved
            self.segment = segment
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRecallMetricView(_ item: TieredRecallMetric) -> TieredRecallMetricView {
        return TieredRecallMetricView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            limitText: String(item.limit),
            approved: "\(item.approved)",
            segment: Kit.Text.truncate(item.segment, limit: 120),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRecallMetricViews(_ items: [TieredRecallMetric]) -> [TieredRecallMetricView] {
        var views: [TieredRecallMetricView] = []
        for item in items {
            views.append(toTieredRecallMetricView(item))
        }
        return views
    }

    static func sumTieredRecallMetricView(_ view: TieredRecallMetricView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return Double(parsedLimit)
    }
}
