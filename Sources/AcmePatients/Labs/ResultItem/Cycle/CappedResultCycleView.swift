import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a capped result cycle.
    final class CappedResultCycleView {
        var code: String
        var label: String
        var budget: String
        var procedureCode: String
        var maximum: String
        var region: String
        var unit: String
        var country: String
        var currencyText: String
        var priority: String
        var statusLabel: String

        init(code: String, label: String, budget: String, procedureCode: String, maximum: String, region: String, unit: String, country: String, currencyText: String, priority: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.budget = budget
            self.procedureCode = procedureCode
            self.maximum = maximum
            self.region = region
            self.unit = unit
            self.country = country
            self.currencyText = currencyText
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toCappedResultCycleView(_ item: CappedResultCycle) -> CappedResultCycleView {
        return CappedResultCycleView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            budget: String(format: "%.2f", item.budget),
            procedureCode: item.procedureCode,
            maximum: String(format: "%.2f", item.maximum),
            region: item.region,
            unit: item.unit,
            country: item.country,
            currencyText: item.currency,
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedResultCycleViews(_ items: [CappedResultCycle]) -> [CappedResultCycleView] {
        var views: [CappedResultCycleView] = []
        for item in items {
            views.append(toCappedResultCycleView(item))
        }
        return views
    }

    static func sumCappedResultCycleView(_ view: CappedResultCycleView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedBudget + parsedMaximum + Double(parsedPriority)
    }
}
