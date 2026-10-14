import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeAdaptivePriorityGroupsForReview(_ items: [AdaptivePriorityGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func derivePrimaryModalityReviewsFromGroup(_ items: [AdaptivePriorityGroup]) -> [PrimaryModalityReview] {
        var out: [PrimaryModalityReview] = []
        for item in items {
            let derived = newPrimaryModalityReview(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func mergePrimaryModalityReview(_ item: PrimaryModalityReview) -> String {
        return normalizeSeasonalPriorityAgreementCode(item.code)
    }
}
