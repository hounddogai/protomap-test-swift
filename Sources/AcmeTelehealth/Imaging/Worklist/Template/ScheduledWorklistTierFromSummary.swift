import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeScheduledModalitySummariesForTier(_ items: [ScheduledModalitySummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveScheduledWorklistTiersFromSummary(_ items: [ScheduledModalitySummary]) -> [ScheduledWorklistTier] {
        var out: [ScheduledWorklistTier] = []
        for item in items {
            let derived = newScheduledWorklistTier(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleScheduledWorklistTier(_ item: ScheduledWorklistTier) -> Double {
        return tieredModalityVarianceWeight(2, active: true)
    }
}
