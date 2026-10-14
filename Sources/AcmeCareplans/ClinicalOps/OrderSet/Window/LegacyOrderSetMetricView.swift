import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a legacy order set metric.
    final class LegacyOrderSetMetricView {
        var code: String
        var nameText: String
        var startsAt: String
        var summary: String
        var ward: String
        var statusLabel: String

        init(code: String, nameText: String, startsAt: String, summary: String, ward: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.startsAt = startsAt
            self.summary = summary
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyOrderSetMetricView(_ item: LegacyOrderSetMetric) -> LegacyOrderSetMetricView {
        return LegacyOrderSetMetricView(
            code: item.code,
            nameText: item.name,
            startsAt: String(item.startsAt),
            summary: item.summary,
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyOrderSetMetricViews(_ items: [LegacyOrderSetMetric]) -> [LegacyOrderSetMetricView] {
        var views: [LegacyOrderSetMetricView] = []
        for item in items {
            views.append(toLegacyOrderSetMetricView(item))
        }
        return views
    }

    static func sumLegacyOrderSetMetricView(_ view: LegacyOrderSetMetricView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
