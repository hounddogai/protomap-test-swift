import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeScheduledAuthorizationMetricsForGroup(_ items: [ScheduledAuthorizationMetric]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveSeasonalRemittanceGroupsFromMetric(_ items: [ScheduledAuthorizationMetric]) -> [SeasonalRemittanceGroup] {
        var out: [SeasonalRemittanceGroup] = []
        for item in items {
            let derived = newSeasonalRemittanceGroup(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileSeasonalRemittanceGroup(_ item: SeasonalRemittanceGroup) -> String {
        return authorizationEstimateBucket(item.effectiveExposure())
    }
}
