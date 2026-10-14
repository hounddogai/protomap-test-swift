import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialPoliciesForBatch(_ items: [DenialPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveAuthorizationBatchesFromPolicy(_ items: [DenialPolicy]) -> [AuthorizationBatch] {
        var out: [AuthorizationBatch] = []
        for item in items {
            let derived = newAuthorizationBatch(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeAuthorizationBatch(_ item: AuthorizationBatch) -> String {
        return normalizeFallbackDenialRuleCode(item.code)
    }
}
