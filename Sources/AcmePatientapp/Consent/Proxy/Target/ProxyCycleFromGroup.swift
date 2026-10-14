import AcmePlatform
import Foundation

extension Consent {
    static func summarizeSeasonalProxyGroupsForCycle(_ items: [SeasonalProxyGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveProxyCyclesFromGroup(_ items: [SeasonalProxyGroup]) -> [ProxyCycle] {
        var out: [ProxyCycle] = []
        for item in items {
            let derived = newProxyCycle(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveProxyCycle(_ item: ProxyCycle) -> String {
        return scheduledProxyGroupBucket(item.effectiveTotal())
    }
}
