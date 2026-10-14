import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeWeightedRecallBundlesForScore(_ items: [WeightedRecallBundle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveAdaptiveInteractionScoresFromBundle(_ items: [WeightedRecallBundle]) -> [AdaptiveInteractionScore] {
        var out: [AdaptiveInteractionScore] = []
        for item in items {
            let derived = newAdaptiveInteractionScore(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAdaptiveInteractionScore(_ item: AdaptiveInteractionScore) -> String {
        return normalizeRecallTargetCode(item.code)
    }
}
