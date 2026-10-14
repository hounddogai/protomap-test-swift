import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeLenientClaimProfilesForBatch(_ items: [LenientClaimProfile]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveTieredRemittanceBatchesFromProfile(_ items: [LenientClaimProfile]) -> [TieredRemittanceBatch] {
        var out: [TieredRemittanceBatch] = []
        for item in items {
            let derived = newTieredRemittanceBatch(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchTieredRemittanceBatch(_ item: TieredRemittanceBatch) -> Double {
        return globalClaimScoreWeight(1, active: true)
    }
}
