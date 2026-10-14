import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeBatchedEligibilityScoresForTarget(_ items: [BatchedEligibilityScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveLenientReferralTargetsFromScore(_ items: [BatchedEligibilityScore]) -> [LenientReferralTarget] {
        var out: [LenientReferralTarget] = []
        for item in items {
            let derived = newLenientReferralTarget(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleLenientReferralTarget(_ item: LenientReferralTarget) -> String {
        return batchedEligibilityScoreBucket(item.weightedExposure())
    }
}
