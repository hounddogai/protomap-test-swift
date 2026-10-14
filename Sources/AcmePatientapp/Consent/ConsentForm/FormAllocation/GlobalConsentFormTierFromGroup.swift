import AcmePlatform
import Foundation

extension Consent {
    static func summarizeWeightedProxyGroupsForTier(_ items: [WeightedProxyGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveGlobalConsentFormTiersFromGroup(_ items: [WeightedProxyGroup]) -> [GlobalConsentFormTier] {
        var out: [GlobalConsentFormTier] = []
        for item in items {
            let derived = newGlobalConsentFormTier(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyGlobalConsentFormTierExtra(_ item: GlobalConsentFormTier) -> String {
        return classifyWeightedProxyGroup(item.netTotal())
    }
}
