import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeCareProtocolProposalsForScore(_ items: [CareProtocolProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveVolume()
        }
        return totals
    }

    static func deriveBatchedAlertScoresFromProposal(_ items: [CareProtocolProposal]) -> [BatchedAlertScore] {
        var out: [BatchedAlertScore] = []
        for item in items {
            let derived = newBatchedAlertScore(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceBatchedAlertScore(_ item: BatchedAlertScore) -> Double {
        return careProtocolProposalWeight(8, active: true)
    }
}
