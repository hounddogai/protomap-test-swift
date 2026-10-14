import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePrimaryOrderSetDraftsForReview(_ items: [PrimaryOrderSetDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveScheduledTaskReviewsFromDraft(_ items: [PrimaryOrderSetDraft]) -> [ScheduledTaskReview] {
        var out: [ScheduledTaskReview] = []
        for item in items {
            let derived = newScheduledTaskReview(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveScheduledTaskReview(_ item: ScheduledTaskReview) -> String {
        return classifyStrictOrderSetTier(item.weightedLoad())
    }
}
