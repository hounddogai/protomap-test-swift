import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeWeightedReferralCyclesForBundle(_ items: [WeightedReferralCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptiveNetworkBundlesFromCycle(_ items: [WeightedReferralCycle]) -> [AdaptiveNetworkBundle] {
        var out: [AdaptiveNetworkBundle] = []
        for item in items {
            let derived = newAdaptiveNetworkBundle(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func planAdaptiveNetworkBundle(_ item: AdaptiveNetworkBundle) -> String {
        return classifyWeightedReferralCycle(item.adjustedLoad())
    }
}
