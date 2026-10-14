import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingCareProtocolMilestonesForTarget(_ items: [PendingCareProtocolMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func derivePendingHandoffTargetsFromMilestone(_ items: [PendingCareProtocolMilestone]) -> [PendingHandoffTarget] {
        var out: [PendingHandoffTarget] = []
        for item in items {
            let derived = newPendingHandoffTarget(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergePendingHandoffTarget(_ item: PendingHandoffTarget) -> String {
        return classifyCareProtocolSlot(item.netExposure())
    }
}
