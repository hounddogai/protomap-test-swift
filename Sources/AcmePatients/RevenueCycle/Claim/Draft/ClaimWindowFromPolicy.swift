import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeDenialPoliciesForWindow(_ items: [DenialPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveClaimWindowsFromPolicy(_ items: [DenialPolicy]) -> [ClaimWindow] {
        var out: [ClaimWindow] = []
        for item in items {
            let derived = newClaimWindow(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectClaimWindow(_ item: ClaimWindow) -> String {
        return normalizeFallbackDenialRuleCode(item.code)
    }
}
