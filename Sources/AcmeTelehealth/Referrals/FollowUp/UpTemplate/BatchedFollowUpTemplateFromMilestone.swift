import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFallbackSlotMilestonesForTemplate(_ items: [FallbackSlotMilestone]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveBatchedFollowUpTemplatesFromMilestone(_ items: [FallbackSlotMilestone]) -> [BatchedFollowUpTemplate] {
        var out: [BatchedFollowUpTemplate] = []
        for item in items {
            let derived = newBatchedFollowUpTemplate(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileBatchedFollowUpTemplateExtra(_ item: BatchedFollowUpTemplate) -> String {
        return normalizeFallbackSlotMilestoneCode(item.code)
    }
}
