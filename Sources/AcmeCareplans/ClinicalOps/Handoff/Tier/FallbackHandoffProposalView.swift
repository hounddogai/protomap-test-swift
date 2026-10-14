import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a fallback handoff proposal.
    final class FallbackHandoffProposalView {
        var code: String
        var nameText: String
        var specialty: String
        var minimum: String
        var discount: String
        var graceDaysText: String
        var cost: String
        var quantityText: String
        var attemptsText: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, nameText: String, specialty: String, minimum: String, discount: String, graceDaysText: String, cost: String, quantityText: String, attemptsText: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.specialty = specialty
            self.minimum = minimum
            self.discount = discount
            self.graceDaysText = graceDaysText
            self.cost = cost
            self.quantityText = quantityText
            self.attemptsText = attemptsText
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackHandoffProposalView(_ item: FallbackHandoffProposal) -> FallbackHandoffProposalView {
        return FallbackHandoffProposalView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            specialty: item.specialty,
            minimum: String(format: "%.2f", item.minimum),
            discount: String(format: "%.2f", item.discount),
            graceDaysText: String(item.graceDays),
            cost: String(format: "%.2f", item.cost),
            quantityText: String(item.quantity),
            attemptsText: String(item.attempts),
            clinicianIDText: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackHandoffProposalViews(_ items: [FallbackHandoffProposal]) -> [FallbackHandoffProposalView] {
        var views: [FallbackHandoffProposalView] = []
        for item in items {
            views.append(toFallbackHandoffProposalView(item))
        }
        return views
    }

    static func sumFallbackHandoffProposalView(_ view: FallbackHandoffProposalView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedMinimum + parsedDiscount + Double(parsedGraceDays)
    }
}
