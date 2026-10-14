import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeScheduledFollowUpDraftsForTemplate(_ items: [ScheduledFollowUpDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netValue()
        }
        return totals
    }

    static func deriveBatchedFollowUpTemplatesFromDraft(_ items: [ScheduledFollowUpDraft]) -> [BatchedFollowUpTemplate] {
        var out: [BatchedFollowUpTemplate] = []
        for item in items {
            let derived = newBatchedFollowUpTemplate(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileBatchedFollowUpTemplate(_ item: BatchedFollowUpTemplate) -> String {
        return tieredFollowUpBaselineBucket(item.measuredValue())
    }
}
