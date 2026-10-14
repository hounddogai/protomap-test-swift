import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot metric.
    final class SlotMetricView {
        var code: String
        var name: String
        var updatedAt: String
        var durationMinutesText: String
        var unit: String
        var countryText: String
        var statusLabel: String

        init(code: String, name: String, updatedAt: String, durationMinutesText: String, unit: String, countryText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.updatedAt = updatedAt
            self.durationMinutesText = durationMinutesText
            self.unit = unit
            self.countryText = countryText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotMetricView(_ item: SlotMetric) -> SlotMetricView {
        return SlotMetricView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            updatedAt: String(item.updatedAt),
            durationMinutesText: String(item.durationMinutes),
            unit: item.unit,
            countryText: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotMetricViews(_ items: [SlotMetric]) -> [SlotMetricView] {
        var views: [SlotMetricView] = []
        for item in items {
            views.append(toSlotMetricView(item))
        }
        return views
    }

    static func sumSlotMetricView(_ view: SlotMetricView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedDurationMinutes)
    }
}
