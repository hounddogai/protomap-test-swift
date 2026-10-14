import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLenientRiskScoreTargetsForDraft(_ items: [LenientRiskScoreTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func derivePendingCareGapDraftsFromTarget(_ items: [LenientRiskScoreTarget]) -> [PendingCareGapDraft] {
        var out: [PendingCareGapDraft] = []
        for item in items {
            let derived = newPendingCareGapDraft(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignPendingCareGapDraft(_ item: PendingCareGapDraft) -> String {
        return manualRiskScoreGroupBucket(item.weightedTotal())
    }
}
