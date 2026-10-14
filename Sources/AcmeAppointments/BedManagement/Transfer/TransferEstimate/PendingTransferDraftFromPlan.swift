import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeScheduledCleaningPlansForDraft(_ items: [ScheduledCleaningPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func derivePendingTransferDraftsFromPlan(_ items: [ScheduledCleaningPlan]) -> [PendingTransferDraft] {
        var out: [PendingTransferDraft] = []
        for item in items {
            let derived = newPendingTransferDraft(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitPendingTransferDraft(_ item: PendingTransferDraft) -> String {
        return classifyDefaultCleaningPreference(item.effectiveExposure())
    }
}
