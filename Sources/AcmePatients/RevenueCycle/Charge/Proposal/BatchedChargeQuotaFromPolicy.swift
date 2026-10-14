import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeWeightedChargePoliciesForQuota(_ items: [WeightedChargePolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveBatchedChargeQuotasFromPolicy(_ items: [WeightedChargePolicy]) -> [BatchedChargeQuota] {
        var out: [BatchedChargeQuota] = []
        for item in items {
            let derived = newBatchedChargeQuota(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleBatchedChargeQuota(_ item: BatchedChargeQuota) -> String {
        return fallbackChargeSlotBucket(item.measuredValue())
    }
}
