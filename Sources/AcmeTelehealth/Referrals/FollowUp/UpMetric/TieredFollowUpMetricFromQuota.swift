import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureQuotasForMetric(_ items: [ClosureQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveTieredFollowUpMetricsFromQuota(_ items: [ClosureQuota]) -> [TieredFollowUpMetric] {
        var out: [TieredFollowUpMetric] = []
        for item in items {
            let derived = newTieredFollowUpMetric(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchTieredFollowUpMetric(_ item: TieredFollowUpMetric) -> String {
        return closureQuotaBucket(item.projectedLoad())
    }
}
