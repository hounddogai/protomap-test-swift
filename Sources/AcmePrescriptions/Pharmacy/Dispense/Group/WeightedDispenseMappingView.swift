import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a weighted dispense mapping.
    final class WeightedDispenseMappingView {
        var code: String
        var label: String
        var nameText: String
        var capacity: String
        var payer: String
        var budget: String
        var notes: String
        var statusLabel: String

        init(code: String, label: String, nameText: String, capacity: String, payer: String, budget: String, notes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.nameText = nameText
            self.capacity = capacity
            self.payer = payer
            self.budget = budget
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedDispenseMappingView(_ item: WeightedDispenseMapping) -> WeightedDispenseMappingView {
        return WeightedDispenseMappingView(
            code: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 80),
            nameText: item.name,
            capacity: String(item.capacity),
            payer: item.payer,
            budget: String(format: "%.2f", item.budget),
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedDispenseMappingViews(_ items: [WeightedDispenseMapping]) -> [WeightedDispenseMappingView] {
        var views: [WeightedDispenseMappingView] = []
        for item in items {
            views.append(toWeightedDispenseMappingView(item))
        }
        return views
    }

    static func sumWeightedDispenseMappingView(_ view: WeightedDispenseMappingView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedCapacity) + parsedBudget
    }
}
