import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeWeightedInteractionDigestsForScore(_ items: [WeightedInteractionDigest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveAdaptiveInteractionScoresFromDigest(_ items: [WeightedInteractionDigest]) -> [AdaptiveInteractionScore] {
        var out: [AdaptiveInteractionScore] = []
        for item in items {
            let derived = newAdaptiveInteractionScore(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeAdaptiveInteractionScore(_ item: AdaptiveInteractionScore) -> String {
        return adaptiveInteractionLedgerBucket(item.weightedTotal())
    }
}
