import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredSlotMappingsForPlan(_ items: [TieredSlotMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveManualNetworkPlansFromMapping(_ items: [TieredSlotMapping]) -> [ManualNetworkPlan] {
        var out: [ManualNetworkPlan] = []
        for item in items {
            let derived = newManualNetworkPlan(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeManualNetworkPlan(_ item: ManualNetworkPlan) -> String {
        return seasonalSlotMappingBucket(item.effectiveValue())
    }
}
