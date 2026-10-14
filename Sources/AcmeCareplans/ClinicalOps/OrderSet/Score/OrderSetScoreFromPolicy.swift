import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeSeasonalHandoffPoliciesForScore(_ items: [SeasonalHandoffPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveOrderSetScoresFromPolicy(_ items: [SeasonalHandoffPolicy]) -> [OrderSetScore] {
        var out: [OrderSetScore] = []
        for item in items {
            let derived = newOrderSetScore(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeOrderSetScore(_ item: OrderSetScore) -> String {
        return fallbackHandoffPlanBucket(item.effectiveValue())
    }
}
