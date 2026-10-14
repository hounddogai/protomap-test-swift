import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a weighted worklist budget.
    final class WeightedWorklistBudgetView {
        var codeText: String
        var labelText: String
        var capacity: String
        var timezone: String
        var bed: String
        var notes: String
        var amount: String
        var statusLabel: String

        init(codeText: String, labelText: String, capacity: String, timezone: String, bed: String, notes: String, amount: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.capacity = capacity
            self.timezone = timezone
            self.bed = bed
            self.notes = notes
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedWorklistBudgetView(_ item: WeightedWorklistBudget) -> WeightedWorklistBudgetView {
        return WeightedWorklistBudgetView(
            codeText: item.code,
            labelText: item.label,
            capacity: String(item.capacity),
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            bed: item.bed,
            notes: item.notes,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedWorklistBudgetViews(_ items: [WeightedWorklistBudget]) -> [WeightedWorklistBudgetView] {
        var views: [WeightedWorklistBudgetView] = []
        for item in items {
            views.append(toWeightedWorklistBudgetView(item))
        }
        return views
    }

    static func sumWeightedWorklistBudgetView(_ view: WeightedWorklistBudgetView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedCapacity) + parsedAmount
    }
}
