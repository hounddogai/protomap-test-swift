import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapSnapshotsForDraft(_ items: [CareGapSnapshot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingCareGapDraftsFromSnapshot(_ items: [CareGapSnapshot]) -> [PendingCareGapDraft] {
        var out: [PendingCareGapDraft] = []
        for item in items {
            let derived = newPendingCareGapDraft(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func classifyPendingCareGapDraftExtra(_ item: PendingCareGapDraft) -> String {
        return classifyCareGapEstimate(item.weightedTotal())
    }
}
