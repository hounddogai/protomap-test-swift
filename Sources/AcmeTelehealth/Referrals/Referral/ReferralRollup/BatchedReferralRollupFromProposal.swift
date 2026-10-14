import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeManualEligibilityProposalsForRollup(_ items: [ManualEligibilityProposal]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveBatchedReferralRollupsFromProposal(_ items: [ManualEligibilityProposal]) -> [BatchedReferralRollup] {
        var out: [BatchedReferralRollup] = []
        for item in items {
            let derived = newBatchedReferralRollup(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateBatchedReferralRollup(_ item: BatchedReferralRollup) -> Double {
        return cappedEligibilityMilestoneWeight(3, active: true)
    }
}
