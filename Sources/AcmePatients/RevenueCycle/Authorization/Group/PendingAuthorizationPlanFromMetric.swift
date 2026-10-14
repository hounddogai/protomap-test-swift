import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeSeasonalDenialMetricsForPlan(_ items: [SeasonalDenialMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func derivePendingAuthorizationPlansFromMetric(_ items: [SeasonalDenialMetric]) -> [PendingAuthorizationPlan] {
        var out: [PendingAuthorizationPlan] = []
        for item in items {
            let derived = newPendingAuthorizationPlan(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergePendingAuthorizationPlan(_ item: PendingAuthorizationPlan) -> Double {
        return seasonalDenialMetricWeight(5, active: true)
    }
}
