import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimBatchesForEstimate(_ items: [ClaimBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveBatchedClaimEstimatesFromBatch(_ items: [ClaimBatch]) -> [BatchedClaimEstimate] {
        var out: [BatchedClaimEstimate] = []
        for item in items {
            let derived = newBatchedClaimEstimate(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceBatchedClaimEstimate(_ item: BatchedClaimEstimate) -> String {
        return claimBatchBucket(item.measuredValue())
    }
}
