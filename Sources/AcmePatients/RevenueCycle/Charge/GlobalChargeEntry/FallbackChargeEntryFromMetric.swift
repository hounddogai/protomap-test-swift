import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeClaimMetricsForEntry(_ items: [ClaimMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveFallbackChargeEntriesFromMetric(_ items: [ClaimMetric]) -> [FallbackChargeEntry] {
        var out: [FallbackChargeEntry] = []
        for item in items {
            let derived = newFallbackChargeEntry(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitFallbackChargeEntry(_ item: FallbackChargeEntry) -> String {
        return normalizeClaimRollupCode(item.code)
    }
}
