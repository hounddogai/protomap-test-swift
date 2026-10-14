import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeClosureMilestonesForManifest(_ items: [ClosureMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingSlotManifestsFromMilestone(_ items: [ClosureMilestone]) -> [PendingSlotManifest] {
        var out: [PendingSlotManifest] = []
        for item in items {
            let derived = newPendingSlotManifest(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchPendingSlotManifest(_ item: PendingSlotManifest) -> Double {
        return closureMilestoneWeight(1, active: true)
    }
}
