import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool budget.
    final class FloatPoolBudgetView {
        var codeText: String
        var label: String
        var approvedText: String
        var cost: String
        var segment: String
        var capacity: String
        var source: String
        var maximum: String
        var externalRefText: String
        var statusLabel: String

        init(codeText: String, label: String, approvedText: String, cost: String, segment: String, capacity: String, source: String, maximum: String, externalRefText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.approvedText = approvedText
            self.cost = cost
            self.segment = segment
            self.capacity = capacity
            self.source = source
            self.maximum = maximum
            self.externalRefText = externalRefText
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolBudgetView(_ item: FloatPoolBudget) -> FloatPoolBudgetView {
        return FloatPoolBudgetView(
            codeText: item.code,
            label: item.label,
            approvedText: "\(item.approved)",
            cost: String(format: "%.2f", item.cost),
            segment: Kit.Text.truncate(item.segment, limit: 80),
            capacity: String(item.capacity),
            source: item.source,
            maximum: String(format: "%.2f", item.maximum),
            externalRefText: item.externalRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolBudgetViews(_ items: [FloatPoolBudget]) -> [FloatPoolBudgetView] {
        var views: [FloatPoolBudgetView] = []
        for item in items {
            views.append(toFloatPoolBudgetView(item))
        }
        return views
    }

    static func sumFloatPoolBudgetView(_ view: FloatPoolBudgetView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCost + Double(parsedCapacity) + parsedMaximum
    }
}
