import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePrimaryOutreachReviewsForItem(_ items: [PrimaryOutreachReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveAdaptiveRiskScoreItemsFromReview(_ items: [PrimaryOutreachReview]) -> [AdaptiveRiskScoreItem] {
        var out: [AdaptiveRiskScoreItem] = []
        for item in items {
            let derived = newAdaptiveRiskScoreItem(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileAdaptiveRiskScoreItem(_ item: AdaptiveRiskScoreItem) -> String {
        return normalizeOutreachDraftCode(item.code)
    }
}
