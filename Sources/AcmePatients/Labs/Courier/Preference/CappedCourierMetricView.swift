import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped courier metric.
    final class CappedCourierMetricView {
        var code: String
        var name: String
        var visibleText: String
        var budget: String
        var visitMinutes: String
        var costText: String
        var phone: String
        var retries: String
        var statusLabel: String

        init(code: String, name: String, visibleText: String, budget: String, visitMinutes: String, costText: String, phone: String, retries: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.visibleText = visibleText
            self.budget = budget
            self.visitMinutes = visitMinutes
            self.costText = costText
            self.phone = phone
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toCappedCourierMetricView(_ item: CappedCourierMetric) -> CappedCourierMetricView {
        return CappedCourierMetricView(
            code: item.code,
            name: item.name,
            visibleText: "\(item.visible)",
            budget: String(format: "%.2f", item.budget),
            visitMinutes: String(item.visitMinutes),
            costText: String(format: "%.2f", item.cost),
            phone: item.phone,
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedCourierMetricViews(_ items: [CappedCourierMetric]) -> [CappedCourierMetricView] {
        var views: [CappedCourierMetricView] = []
        for item in items {
            views.append(toCappedCourierMetricView(item))
        }
        return views
    }

    static func sumCappedCourierMetricView(_ view: CappedCourierMetricView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedBudget + Double(parsedVisitMinutes) + parsedCost
    }
}
