import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeEligibilityPoliciesForManifest(_ items: [EligibilityPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveManualNetworkManifestsFromPolicy(_ items: [EligibilityPolicy]) -> [ManualNetworkManifest] {
        var out: [ManualNetworkManifest] = []
        for item in items {
            let derived = newManualNetworkManifest(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveManualNetworkManifest(_ item: ManualNetworkManifest) -> String {
        return eligibilityPolicyBucket(item.adjustedTotal())
    }
}
