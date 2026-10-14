import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a manual courier metric.
    final class ManualCourierMetricView {
        var code: String
        var title: String
        var threshold: String
        var retries: String
        var durationMinutes: String
        var maximum: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, title: String, threshold: String, retries: String, durationMinutes: String, maximum: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.retries = retries
            self.durationMinutes = durationMinutes
            self.maximum = maximum
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toManualCourierMetricView(_ item: ManualCourierMetric) -> ManualCourierMetricView {
        return ManualCourierMetricView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            threshold: String(format: "%.2f", item.threshold),
            retries: String(item.retries),
            durationMinutes: String(item.durationMinutes),
            maximum: String(format: "%.2f", item.maximum),
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualCourierMetricViews(_ items: [ManualCourierMetric]) -> [ManualCourierMetricView] {
        var views: [ManualCourierMetricView] = []
        for item in items {
            views.append(toManualCourierMetricView(item))
        }
        return views
    }

    static func sumManualCourierMetricView(_ view: ManualCourierMetricView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedThreshold + Double(parsedRetries) + Double(parsedDurationMinutes)
    }
}
