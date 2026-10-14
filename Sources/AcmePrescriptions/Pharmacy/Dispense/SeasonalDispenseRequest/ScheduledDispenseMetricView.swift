import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a scheduled dispense metric.
    final class ScheduledDispenseMetricView {
        var code: String
        var nameText: String
        var maximum: String
        var visible: String
        var durationMinutesText: String
        var rate: String
        var contactEmail: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, nameText: String, maximum: String, visible: String, durationMinutesText: String, rate: String, contactEmail: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.maximum = maximum
            self.visible = visible
            self.durationMinutesText = durationMinutesText
            self.rate = rate
            self.contactEmail = contactEmail
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledDispenseMetricView(_ item: ScheduledDispenseMetric) -> ScheduledDispenseMetricView {
        return ScheduledDispenseMetricView(
            code: item.code,
            nameText: item.name,
            maximum: String(format: "%.2f", item.maximum),
            visible: "\(item.visible)",
            durationMinutesText: String(item.durationMinutes),
            rate: String(format: "%.2f", item.rate),
            contactEmail: item.contactEmail,
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledDispenseMetricViews(_ items: [ScheduledDispenseMetric]) -> [ScheduledDispenseMetricView] {
        var views: [ScheduledDispenseMetricView] = []
        for item in items {
            views.append(toScheduledDispenseMetricView(item))
        }
        return views
    }

    static func sumScheduledDispenseMetricView(_ view: ScheduledDispenseMetricView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedMaximum + Double(parsedDurationMinutes) + parsedRate
    }
}
