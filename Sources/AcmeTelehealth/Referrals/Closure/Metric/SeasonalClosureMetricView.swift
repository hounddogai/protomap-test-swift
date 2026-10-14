import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal closure metric.
    final class SeasonalClosureMetricView {
        var code: String
        var name: String
        var channel: String
        var maximum: String
        var budget: String
        var capacity: String
        var statusLabel: String

        init(code: String, name: String, channel: String, maximum: String, budget: String, capacity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.channel = channel
            self.maximum = maximum
            self.budget = budget
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalClosureMetricView(_ item: SeasonalClosureMetric) -> SeasonalClosureMetricView {
        return SeasonalClosureMetricView(
            code: item.code,
            name: item.name,
            channel: Kit.Text.truncate(item.channel, limit: 40),
            maximum: String(format: "%.2f", item.maximum),
            budget: String(format: "%.2f", item.budget),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalClosureMetricViews(_ items: [SeasonalClosureMetric]) -> [SeasonalClosureMetricView] {
        var views: [SeasonalClosureMetricView] = []
        for item in items {
            views.append(toSeasonalClosureMetricView(item))
        }
        return views
    }

    static func sumSeasonalClosureMetricView(_ view: SeasonalClosureMetricView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedMaximum + parsedBudget + Double(parsedCapacity)
    }
}
