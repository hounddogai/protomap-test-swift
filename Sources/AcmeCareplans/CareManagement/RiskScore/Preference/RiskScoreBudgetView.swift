import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score budget.
    final class RiskScoreBudgetView {
        var code: String
        var name: String
        var attempts: String
        var graceDays: String
        var patientRefText: String
        var statusLabel: String

        init(code: String, name: String, attempts: String, graceDays: String, patientRefText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.attempts = attempts
            self.graceDays = graceDays
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreBudgetView(_ item: RiskScoreBudget) -> RiskScoreBudgetView {
        return RiskScoreBudgetView(
            code: item.code,
            name: item.name,
            attempts: String(item.attempts),
            graceDays: String(item.graceDays),
            patientRefText: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreBudgetViews(_ items: [RiskScoreBudget]) -> [RiskScoreBudgetView] {
        var views: [RiskScoreBudgetView] = []
        for item in items {
            views.append(toRiskScoreBudgetView(item))
        }
        return views
    }

    static func sumRiskScoreBudgetView(_ view: RiskScoreBudgetView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedAttempts) + Double(parsedGraceDays)
    }
}
