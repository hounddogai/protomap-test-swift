import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeBatchedRiskScoreProposalsForVariance(_ items: [BatchedRiskScoreProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveManualCareGapVariancesFromProposal(_ items: [BatchedRiskScoreProposal]) -> [ManualCareGapVariance] {
        var out: [ManualCareGapVariance] = []
        for item in items {
            let derived = newManualCareGapVariance(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveManualCareGapVariance(_ item: ManualCareGapVariance) -> String {
        return normalizeBatchedRiskScoreProposalCode(item.code)
    }
}
