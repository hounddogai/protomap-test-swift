import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted slot ledger.
    final class WeightedSlotLedgerView {
        var codeText: String
        var labelText: String
        var weightText: String
        var budget: String
        var specialtyText: String
        var copay: String
        var name: String
        var statusLabel: String

        init(codeText: String, labelText: String, weightText: String, budget: String, specialtyText: String, copay: String, name: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.weightText = weightText
            self.budget = budget
            self.specialtyText = specialtyText
            self.copay = copay
            self.name = name
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedSlotLedgerView(_ item: WeightedSlotLedger) -> WeightedSlotLedgerView {
        return WeightedSlotLedgerView(
            codeText: item.code,
            labelText: item.label,
            weightText: String(format: "%.2f", item.weight),
            budget: String(format: "%.2f", item.budget),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 80),
            copay: String(format: "%.2f", item.copay),
            name: item.name,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedSlotLedgerViews(_ items: [WeightedSlotLedger]) -> [WeightedSlotLedgerView] {
        var views: [WeightedSlotLedgerView] = []
        for item in items {
            views.append(toWeightedSlotLedgerView(item))
        }
        return views
    }

    static func sumWeightedSlotLedgerView(_ view: WeightedSlotLedgerView) throws -> Double {
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedWeight + parsedBudget + parsedCopay
    }
}
