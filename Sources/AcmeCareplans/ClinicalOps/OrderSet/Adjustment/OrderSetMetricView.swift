import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set metric.
    final class OrderSetMetricView {
        var code: String
        var title: String
        var windowDays: String
        var budgetText: String
        var priority: String
        var pinnedText: String
        var name: String
        var source: String
        var statusLabel: String

        init(code: String, title: String, windowDays: String, budgetText: String, priority: String, pinnedText: String, name: String, source: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.budgetText = budgetText
            self.priority = priority
            self.pinnedText = pinnedText
            self.name = name
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetMetricView(_ item: OrderSetMetric) -> OrderSetMetricView {
        return OrderSetMetricView(
            code: item.code,
            title: item.title,
            windowDays: String(item.windowDays),
            budgetText: String(format: "%.2f", item.budget),
            priority: String(item.priority),
            pinnedText: "\(item.pinned)",
            name: item.name,
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetMetricViews(_ items: [OrderSetMetric]) -> [OrderSetMetricView] {
        var views: [OrderSetMetricView] = []
        for item in items {
            views.append(toOrderSetMetricView(item))
        }
        return views
    }

    static func sumOrderSetMetricView(_ view: OrderSetMetricView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedWindowDays) + parsedBudget + Double(parsedPriority)
    }
}
