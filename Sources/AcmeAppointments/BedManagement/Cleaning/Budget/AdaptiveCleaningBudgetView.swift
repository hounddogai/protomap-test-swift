import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive cleaning budget.
    final class AdaptiveCleaningBudgetView {
        var codeText: String
        var label: String
        var patientRef: String
        var currency: String
        var floorValue: String
        var cost: String
        var allergy: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, patientRef: String, currency: String, floorValue: String, cost: String, allergy: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.patientRef = patientRef
            self.currency = currency
            self.floorValue = floorValue
            self.cost = cost
            self.allergy = allergy
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCleaningBudgetView(_ item: AdaptiveCleaningBudget) -> AdaptiveCleaningBudgetView {
        return AdaptiveCleaningBudgetView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: item.label,
            patientRef: item.patientRef,
            currency: Kit.Text.truncate(item.currency, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            cost: String(format: "%.2f", item.cost),
            allergy: item.allergy,
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCleaningBudgetViews(_ items: [AdaptiveCleaningBudget]) -> [AdaptiveCleaningBudgetView] {
        var views: [AdaptiveCleaningBudgetView] = []
        for item in items {
            views.append(toAdaptiveCleaningBudgetView(item))
        }
        return views
    }

    static func sumAdaptiveCleaningBudgetView(_ view: AdaptiveCleaningBudgetView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedFloorValue + parsedCost + Double(parsedDurationMinutes)
    }
}
