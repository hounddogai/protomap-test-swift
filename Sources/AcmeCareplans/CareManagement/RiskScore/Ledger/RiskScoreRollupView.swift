import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score rollup.
    final class RiskScoreRollupView {
        var codeText: String
        var name: String
        var weight: String
        var currency: String
        var amountText: String
        var attemptsText: String
        var acuity: String
        var statusLabel: String

        init(codeText: String, name: String, weight: String, currency: String, amountText: String, attemptsText: String, acuity: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.weight = weight
            self.currency = currency
            self.amountText = amountText
            self.attemptsText = attemptsText
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreRollupView(_ item: RiskScoreRollup) -> RiskScoreRollupView {
        return RiskScoreRollupView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 120),
            weight: String(format: "%.2f", item.weight),
            currency: item.currency,
            amountText: String(format: "%.2f", item.amount),
            attemptsText: String(item.attempts),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreRollupViews(_ items: [RiskScoreRollup]) -> [RiskScoreRollupView] {
        var views: [RiskScoreRollupView] = []
        for item in items {
            views.append(toRiskScoreRollupView(item))
        }
        return views
    }

    static func sumRiskScoreRollupView(_ view: RiskScoreRollupView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return parsedWeight + parsedAmount + Double(parsedAttempts)
    }
}
