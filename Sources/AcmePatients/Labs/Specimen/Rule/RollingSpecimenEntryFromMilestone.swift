import AcmePlatform
import Foundation

extension Labs {
    static func summarizeAdaptivePanelMilestonesForEntry(_ items: [AdaptivePanelMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRollingSpecimenEntriesFromMilestone(_ items: [AdaptivePanelMilestone]) -> [RollingSpecimenEntry] {
        var out: [RollingSpecimenEntry] = []
        for item in items {
            let derived = newRollingSpecimenEntry(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyRollingSpecimenEntry(_ item: RollingSpecimenEntry) -> String {
        return strictPanelPolicyBucket(item.effectiveExposure())
    }
}
