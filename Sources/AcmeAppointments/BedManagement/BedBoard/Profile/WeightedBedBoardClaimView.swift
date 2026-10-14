import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a weighted bed board claim.
    final class WeightedBedBoardClaimView {
        var codeText: String
        var name: String
        var categoryText: String
        var label: String
        var weight: String
        var payerText: String
        var amount: String
        var attempts: String
        var dosageMg: String
        var sequence: String
        var statusLabel: String

        init(codeText: String, name: String, categoryText: String, label: String, weight: String, payerText: String, amount: String, attempts: String, dosageMg: String, sequence: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.categoryText = categoryText
            self.label = label
            self.weight = weight
            self.payerText = payerText
            self.amount = amount
            self.attempts = attempts
            self.dosageMg = dosageMg
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedBedBoardClaimView(_ item: WeightedBedBoardClaim) -> WeightedBedBoardClaimView {
        return WeightedBedBoardClaimView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            categoryText: Kit.Text.truncate(item.category, limit: 40),
            label: item.label,
            weight: String(format: "%.2f", item.weight),
            payerText: Kit.Text.truncate(item.payer, limit: 64),
            amount: String(format: "%.2f", item.amount),
            attempts: String(item.attempts),
            dosageMg: String(format: "%.2f", item.dosageMg),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedBedBoardClaimViews(_ items: [WeightedBedBoardClaim]) -> [WeightedBedBoardClaimView] {
        var views: [WeightedBedBoardClaimView] = []
        for item in items {
            views.append(toWeightedBedBoardClaimView(item))
        }
        return views
    }

    static func sumWeightedBedBoardClaimView(_ view: WeightedBedBoardClaimView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedWeight + parsedAmount + Double(parsedAttempts)
    }
}
