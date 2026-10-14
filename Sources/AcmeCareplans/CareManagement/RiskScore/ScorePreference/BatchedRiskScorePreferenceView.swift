import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched risk score preference.
    final class BatchedRiskScorePreferenceView {
        var code: String
        var name: String
        var activeText: String
        var patientRef: String
        var payer: String
        var amount: String
        var statusLabel: String

        init(code: String, name: String, activeText: String, patientRef: String, payer: String, amount: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.activeText = activeText
            self.patientRef = patientRef
            self.payer = payer
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedRiskScorePreferenceView(_ item: BatchedRiskScorePreference) -> BatchedRiskScorePreferenceView {
        return BatchedRiskScorePreferenceView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            activeText: "\(item.active)",
            patientRef: item.patientRef,
            payer: item.payer,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedRiskScorePreferenceViews(_ items: [BatchedRiskScorePreference]) -> [BatchedRiskScorePreferenceView] {
        var views: [BatchedRiskScorePreferenceView] = []
        for item in items {
            views.append(toBatchedRiskScorePreferenceView(item))
        }
        return views
    }

    static func sumBatchedRiskScorePreferenceView(_ view: BatchedRiskScorePreferenceView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
