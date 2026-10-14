import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFollowUpPlansForMapping(_ items: [FollowUpPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveSeasonalSlotMappingsFromPlan(_ items: [FollowUpPlan]) -> [SeasonalSlotMapping] {
        var out: [SeasonalSlotMapping] = []
        for item in items {
            let derived = newSeasonalSlotMapping(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planSeasonalSlotMapping(_ item: SeasonalSlotMapping) -> String {
        return followUpPlanBucket(item.effectiveValue())
    }
}
