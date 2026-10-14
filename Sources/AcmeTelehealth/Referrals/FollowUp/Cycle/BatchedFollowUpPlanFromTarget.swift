import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLenientReferralTargetsForPlan(_ items: [LenientReferralTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveBatchedFollowUpPlansFromTarget(_ items: [LenientReferralTarget]) -> [BatchedFollowUpPlan] {
        var out: [BatchedFollowUpPlan] = []
        for item in items {
            let derived = newBatchedFollowUpPlan(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchBatchedFollowUpPlan(_ item: BatchedFollowUpPlan) -> String {
        return referralOverrideBucket(item.measuredValue())
    }
}
