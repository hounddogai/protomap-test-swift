import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a scheduled discharge plan forecast.
    final class ScheduledDischargePlanForecastView {
        var code: String
        var label: String
        var capacity: String
        var reviewer: String
        var score: String
        var copay: String
        var statusLabel: String

        init(code: String, label: String, capacity: String, reviewer: String, score: String, copay: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.reviewer = reviewer
            self.score = score
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledDischargePlanForecastView(_ item: ScheduledDischargePlanForecast) -> ScheduledDischargePlanForecastView {
        return ScheduledDischargePlanForecastView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            capacity: String(item.capacity),
            reviewer: item.reviewer,
            score: String(format: "%.2f", item.score),
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledDischargePlanForecastViews(_ items: [ScheduledDischargePlanForecast]) -> [ScheduledDischargePlanForecastView] {
        var views: [ScheduledDischargePlanForecastView] = []
        for item in items {
            views.append(toScheduledDischargePlanForecastView(item))
        }
        return views
    }

    static func sumScheduledDischargePlanForecastView(_ view: ScheduledDischargePlanForecastView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedCapacity) + parsedScore + parsedCopay
    }
}
