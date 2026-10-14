import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal study metric.
    final class SeasonalStudyMetricView {
        var code: String
        var label: String
        var active: String
        var batchSizeText: String
        var ward: String
        var endsAtText: String
        var timezone: String
        var titleText: String
        var bedText: String
        var durationMinutes: String
        var rate: String
        var statusLabel: String

        init(code: String, label: String, active: String, batchSizeText: String, ward: String, endsAtText: String, timezone: String, titleText: String, bedText: String, durationMinutes: String, rate: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.active = active
            self.batchSizeText = batchSizeText
            self.ward = ward
            self.endsAtText = endsAtText
            self.timezone = timezone
            self.titleText = titleText
            self.bedText = bedText
            self.durationMinutes = durationMinutes
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalStudyMetricView(_ item: SeasonalStudyMetric) -> SeasonalStudyMetricView {
        return SeasonalStudyMetricView(
            code: item.code,
            label: item.label,
            active: "\(item.active)",
            batchSizeText: String(item.batchSize),
            ward: item.ward,
            endsAtText: String(item.endsAt),
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            titleText: Kit.Text.truncate(item.title, limit: 80),
            bedText: item.bed,
            durationMinutes: String(item.durationMinutes),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalStudyMetricViews(_ items: [SeasonalStudyMetric]) -> [SeasonalStudyMetricView] {
        var views: [SeasonalStudyMetricView] = []
        for item in items {
            views.append(toSeasonalStudyMetricView(item))
        }
        return views
    }

    static func sumSeasonalStudyMetricView(_ view: SeasonalStudyMetricView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedBatchSize) + Double(parsedEndsAt) + Double(parsedDurationMinutes)
    }
}
