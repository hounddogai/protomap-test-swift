import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpTiersForBatch(_ items: [FollowUpTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveEligibilityBatchesFromTier(_ items: [FollowUpTier]) -> [EligibilityBatch] {
        var out: [EligibilityBatch] = []
        for item in items {
            let derived = newEligibilityBatch(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileEligibilityBatch(_ item: EligibilityBatch) -> String {
        return followUpDigestBucket(item.weightedTotal())
    }
}
