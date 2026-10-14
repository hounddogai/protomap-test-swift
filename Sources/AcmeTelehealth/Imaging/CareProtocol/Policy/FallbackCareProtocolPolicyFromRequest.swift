import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeWeightedWorklistRequestsForPolicy(_ items: [WeightedWorklistRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netTotal()
        }
        return totals
    }

    static func deriveFallbackCareProtocolPoliciesFromRequest(_ items: [WeightedWorklistRequest]) -> [FallbackCareProtocolPolicy] {
        var out: [FallbackCareProtocolPolicy] = []
        for item in items {
            let derived = newFallbackCareProtocolPolicy(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileFallbackCareProtocolPolicy(_ item: FallbackCareProtocolPolicy) -> String {
        return classifySeasonalWorklistPreference(item.adjustedTotal())
    }
}
