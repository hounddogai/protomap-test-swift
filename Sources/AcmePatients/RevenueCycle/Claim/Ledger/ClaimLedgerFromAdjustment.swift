import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeBatchedRemittanceAdjustmentsForLedger(_ items: [BatchedRemittanceAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveClaimLedgersFromAdjustment(_ items: [BatchedRemittanceAdjustment]) -> [ClaimLedger] {
        var out: [ClaimLedger] = []
        for item in items {
            let derived = newClaimLedger(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeClaimLedger(_ item: ClaimLedger) -> String {
        return batchedRemittanceAdjustmentBucket(item.weightedExposure())
    }
}
