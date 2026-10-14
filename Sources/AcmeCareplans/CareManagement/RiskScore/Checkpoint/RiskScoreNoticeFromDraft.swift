import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingCareGapDraftsForNotice(_ items: [PendingCareGapDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveRiskScoreNoticesFromDraft(_ items: [PendingCareGapDraft]) -> [RiskScoreNotice] {
        var out: [RiskScoreNotice] = []
        for item in items {
            let derived = newRiskScoreNotice(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func planRiskScoreNotice(_ item: RiskScoreNotice) -> String {
        return adaptiveCareGapNoticeBucket(item.projectedLoad())
    }
}
