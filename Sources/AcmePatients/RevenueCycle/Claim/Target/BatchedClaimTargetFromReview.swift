import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeRemittanceReviewsForTarget(_ items: [RemittanceReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveBatchedClaimTargetsFromReview(_ items: [RemittanceReview]) -> [BatchedClaimTarget] {
        var out: [BatchedClaimTarget] = []
        for item in items {
            let derived = newBatchedClaimTarget(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateBatchedClaimTarget(_ item: BatchedClaimTarget) -> String {
        return normalizeSeasonalRemittanceAssignmentCode(item.code)
    }
}
