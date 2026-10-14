import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score claim.
    final class RiskScoreClaimView {
        var code: String
        var label: String
        var country: String
        var notes: String
        var description: String
        var amountText: String
        var statusLabel: String

        init(code: String, label: String, country: String, notes: String, description: String, amountText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.country = country
            self.notes = notes
            self.description = description
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreClaimView(_ item: RiskScoreClaim) -> RiskScoreClaimView {
        return RiskScoreClaimView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            country: Kit.Text.truncate(item.country, limit: 40),
            notes: item.notes,
            description: item.description,
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreClaimViews(_ items: [RiskScoreClaim]) -> [RiskScoreClaimView] {
        var views: [RiskScoreClaimView] = []
        for item in items {
            views.append(toRiskScoreClaimView(item))
        }
        return views
    }

    static func sumRiskScoreClaimView(_ view: RiskScoreClaimView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
