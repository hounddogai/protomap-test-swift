import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimSlotsForQuota(_ items: [ClaimSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveBatchedChargeQuotasFromSlot(_ items: [ClaimSlot]) -> [BatchedChargeQuota] {
        var out: [BatchedChargeQuota] = []
        for item in items {
            let derived = newBatchedChargeQuota(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveBatchedChargeQuota(_ item: BatchedChargeQuota) -> String {
        return normalizeClaimSlotCode(item.code)
    }
}
