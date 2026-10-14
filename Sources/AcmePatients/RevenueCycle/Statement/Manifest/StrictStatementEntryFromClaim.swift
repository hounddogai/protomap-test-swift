import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeFallbackAuthorizationClaimsForEntry(_ items: [FallbackAuthorizationClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveStrictStatementEntriesFromClaim(_ items: [FallbackAuthorizationClaim]) -> [StrictStatementEntry] {
        var out: [StrictStatementEntry] = []
        for item in items {
            let derived = newStrictStatementEntry(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateStrictStatementEntry(_ item: StrictStatementEntry) -> Double {
        return globalAuthorizationEstimateWeight(1, active: true)
    }
}
