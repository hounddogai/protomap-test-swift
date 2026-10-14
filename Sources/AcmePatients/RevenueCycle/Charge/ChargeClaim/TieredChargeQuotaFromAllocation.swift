import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStrictClaimAllocationsForQuota(_ items: [StrictClaimAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveTieredChargeQuotasFromAllocation(_ items: [StrictClaimAllocation]) -> [TieredChargeQuota] {
        var out: [TieredChargeQuota] = []
        for item in items {
            let derived = newTieredChargeQuota(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planTieredChargeQuota(_ item: TieredChargeQuota) -> String {
        return classifyTieredClaimThreshold(item.weightedLoad())
    }
}
