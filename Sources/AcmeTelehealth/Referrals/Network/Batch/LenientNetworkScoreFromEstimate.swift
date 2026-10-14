import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeLenientEligibilityEstimatesForScore(_ items: [LenientEligibilityEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedLoad()
        }
        return totals
    }

    static func deriveLenientNetworkScoresFromEstimate(_ items: [LenientEligibilityEstimate]) -> [LenientNetworkScore] {
        var out: [LenientNetworkScore] = []
        for item in items {
            let derived = newLenientNetworkScore(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateLenientNetworkScore(_ item: LenientNetworkScore) -> Double {
        return pendingEligibilityForecastWeight(7, active: true)
    }
}
