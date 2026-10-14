import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeTieredNetworkEntriesForMilestone(_ items: [TieredNetworkEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveFallbackSlotMilestonesFromEntry(_ items: [TieredNetworkEntry]) -> [FallbackSlotMilestone] {
        var out: [FallbackSlotMilestone] = []
        for item in items {
            let derived = newFallbackSlotMilestone(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileFallbackSlotMilestone(_ item: FallbackSlotMilestone) -> String {
        return networkRequestBucket(item.netExposure())
    }
}
