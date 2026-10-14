import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeNetworkRulesForMapping(_ items: [NetworkRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveCappedEligibilityMappingsFromRule(_ items: [NetworkRule]) -> [CappedEligibilityMapping] {
        var out: [CappedEligibilityMapping] = []
        for item in items {
            let derived = newCappedEligibilityMapping(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeCappedEligibilityMapping(_ item: CappedEligibilityMapping) -> String {
        return classifyNetworkRule(item.weightedVolume())
    }
}
