import AcmePlatform
import Foundation

extension Labs {
    static func summarizeScheduledResultPoliciesForPlan(_ items: [ScheduledResultPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveTieredPanelPlansFromPolicy(_ items: [ScheduledResultPolicy]) -> [TieredPanelPlan] {
        var out: [TieredPanelPlan] = []
        for item in items {
            let derived = newTieredPanelPlan(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveTieredPanelPlan(_ item: TieredPanelPlan) -> String {
        return adaptiveResultBundleBucket(item.adjustedExposure())
    }
}
