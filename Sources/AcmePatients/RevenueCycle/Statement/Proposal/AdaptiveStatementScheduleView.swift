import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a adaptive statement schedule.
    final class AdaptiveStatementScheduleView {
        var code: String
        var label: String
        var capacity: String
        var allergy: String
        var summary: String
        var maximum: String
        var statusLabel: String

        init(code: String, label: String, capacity: String, allergy: String, summary: String, maximum: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.allergy = allergy
            self.summary = summary
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveStatementScheduleView(_ item: AdaptiveStatementSchedule) -> AdaptiveStatementScheduleView {
        return AdaptiveStatementScheduleView(
            code: item.code,
            label: item.label,
            capacity: String(item.capacity),
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            summary: Kit.Text.truncate(item.summary, limit: 120),
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveStatementScheduleViews(_ items: [AdaptiveStatementSchedule]) -> [AdaptiveStatementScheduleView] {
        var views: [AdaptiveStatementScheduleView] = []
        for item in items {
            views.append(toAdaptiveStatementScheduleView(item))
        }
        return views
    }

    static func sumAdaptiveStatementScheduleView(_ view: AdaptiveStatementScheduleView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return Double(parsedCapacity) + parsedMaximum
    }
}
