import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRegionalAssessmentManifestsForReservation(_ items: [RegionalAssessmentManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveRiskScoreReservationsFromManifest(_ items: [RegionalAssessmentManifest]) -> [RiskScoreReservation] {
        var out: [RiskScoreReservation] = []
        for item in items {
            let derived = newRiskScoreReservation(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateRiskScoreReservation(_ item: RiskScoreReservation) -> String {
        return normalizeAssessmentProposalCode(item.code)
    }
}
