import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityBatchesForCycle(_ items: [EligibilityBatch]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveBatchedNetworkCyclesFromBatch(_ items: [EligibilityBatch]) -> [BatchedNetworkCycle] {
        var out: [BatchedNetworkCycle] = []
        for item in items {
            let derived = newBatchedNetworkCycle(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankBatchedNetworkCycle(_ item: BatchedNetworkCycle) -> String {
        return eligibilityBatchBucket(item.measuredValue())
    }
}
