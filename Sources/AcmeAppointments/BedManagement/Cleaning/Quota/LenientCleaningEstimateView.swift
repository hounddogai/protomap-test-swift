import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a lenient cleaning estimate.
    final class LenientCleaningEstimateView {
        var codeText: String
        var name: String
        var acuityText: String
        var budget: String
        var quantity: String
        var durationMinutesText: String
        var diagnosisCode: String
        var notes: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, name: String, acuityText: String, budget: String, quantity: String, durationMinutesText: String, diagnosisCode: String, notes: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.acuityText = acuityText
            self.budget = budget
            self.quantity = quantity
            self.durationMinutesText = durationMinutesText
            self.diagnosisCode = diagnosisCode
            self.notes = notes
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toLenientCleaningEstimateView(_ item: LenientCleaningEstimate) -> LenientCleaningEstimateView {
        return LenientCleaningEstimateView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            acuityText: String(item.acuity),
            budget: String(format: "%.2f", item.budget),
            quantity: String(item.quantity),
            durationMinutesText: String(item.durationMinutes),
            diagnosisCode: item.diagnosisCode,
            notes: item.notes,
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLenientCleaningEstimateViews(_ items: [LenientCleaningEstimate]) -> [LenientCleaningEstimateView] {
        var views: [LenientCleaningEstimateView] = []
        for item in items {
            views.append(toLenientCleaningEstimateView(item))
        }
        return views
    }

    static func sumLenientCleaningEstimateView(_ view: LenientCleaningEstimateView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedAcuity) + parsedBudget + Double(parsedQuantity)
    }
}
