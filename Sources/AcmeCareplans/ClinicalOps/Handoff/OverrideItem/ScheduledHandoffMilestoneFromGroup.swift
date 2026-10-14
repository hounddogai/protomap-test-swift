import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeManualOrderSetGroupsForMilestone(_ items: [ManualOrderSetGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveScheduledHandoffMilestonesFromGroup(_ items: [ManualOrderSetGroup]) -> [ScheduledHandoffMilestone] {
        var out: [ScheduledHandoffMilestone] = []
        for item in items {
            let derived = newScheduledHandoffMilestone(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeScheduledHandoffMilestone(_ item: ScheduledHandoffMilestone) -> Double {
        return primaryOrderSetDigestWeight(3, active: true)
    }
}
