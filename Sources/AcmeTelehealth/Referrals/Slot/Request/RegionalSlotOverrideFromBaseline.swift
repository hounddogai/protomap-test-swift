import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeAdaptiveFollowUpBaselinesForOverride(_ items: [AdaptiveFollowUpBaseline]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveRegionalSlotOverridesFromBaseline(_ items: [AdaptiveFollowUpBaseline]) -> [RegionalSlotOverride] {
        var out: [RegionalSlotOverride] = []
        for item in items {
            let derived = newRegionalSlotOverride(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileRegionalSlotOverride(_ item: RegionalSlotOverride) -> Double {
        return primaryFollowUpAdjustmentWeight(7, active: true)
    }
}
