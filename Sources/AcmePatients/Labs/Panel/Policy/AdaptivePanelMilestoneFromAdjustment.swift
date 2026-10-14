import AcmePlatform
import Foundation

extension Labs {
    static func summarizeStrictSpecimenAdjustmentsForMilestone(_ items: [StrictSpecimenAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAdaptivePanelMilestonesFromAdjustment(_ items: [StrictSpecimenAdjustment]) -> [AdaptivePanelMilestone] {
        var out: [AdaptivePanelMilestone] = []
        for item in items {
            let derived = newAdaptivePanelMilestone(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeAdaptivePanelMilestoneExtra(_ item: AdaptivePanelMilestone) -> String {
        return strictSpecimenAdjustmentBucket(item.measuredValue())
    }
}
