import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted risk score policy.
    final class WeightedRiskScorePolicyView {
        var codeText: String
        var label: String
        var graceDaysText: String
        var clinicianID: String
        var expiresAt: String
        var diagnosisCodeText: String
        var thresholdText: String
        var amountText: String
        var notes: String
        var statusLabel: String

        init(codeText: String, label: String, graceDaysText: String, clinicianID: String, expiresAt: String, diagnosisCodeText: String, thresholdText: String, amountText: String, notes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.graceDaysText = graceDaysText
            self.clinicianID = clinicianID
            self.expiresAt = expiresAt
            self.diagnosisCodeText = diagnosisCodeText
            self.thresholdText = thresholdText
            self.amountText = amountText
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedRiskScorePolicyView(_ item: WeightedRiskScorePolicy) -> WeightedRiskScorePolicyView {
        return WeightedRiskScorePolicyView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            graceDaysText: String(item.graceDays),
            clinicianID: item.clinicianID,
            expiresAt: String(item.expiresAt),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 80),
            thresholdText: String(format: "%.2f", item.threshold),
            amountText: String(format: "%.2f", item.amount),
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedRiskScorePolicyViews(_ items: [WeightedRiskScorePolicy]) -> [WeightedRiskScorePolicyView] {
        var views: [WeightedRiskScorePolicyView] = []
        for item in items {
            views.append(toWeightedRiskScorePolicyView(item))
        }
        return views
    }

    static func sumWeightedRiskScorePolicyView(_ view: WeightedRiskScorePolicyView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedExpiresAt) + parsedThreshold
    }
}
