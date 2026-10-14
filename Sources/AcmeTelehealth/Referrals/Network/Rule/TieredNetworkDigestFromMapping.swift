import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotMappingsForDigest(_ items: [SlotMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveTieredNetworkDigestsFromMapping(_ items: [SlotMapping]) -> [TieredNetworkDigest] {
        var out: [TieredNetworkDigest] = []
        for item in items {
            let derived = newTieredNetworkDigest(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planTieredNetworkDigest(_ item: TieredNetworkDigest) -> String {
        return regionalSlotDigestBucket(item.adjustedTotal())
    }
}
