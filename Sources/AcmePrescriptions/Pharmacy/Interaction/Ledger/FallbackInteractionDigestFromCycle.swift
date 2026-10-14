import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeWeightedRecallCyclesForDigest(_ items: [WeightedRecallCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveFallbackInteractionDigestsFromCycle(_ items: [WeightedRecallCycle]) -> [FallbackInteractionDigest] {
        var out: [FallbackInteractionDigest] = []
        for item in items {
            let derived = newFallbackInteractionDigest(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitFallbackInteractionDigest(_ item: FallbackInteractionDigest) -> String {
        return primaryRecallDigestBucket(item.netLoad())
    }
}
