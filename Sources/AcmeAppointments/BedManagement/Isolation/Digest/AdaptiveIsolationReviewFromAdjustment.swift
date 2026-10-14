import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningAdjustmentsForReview(_ items: [CleaningAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveAdaptiveIsolationReviewsFromAdjustment(_ items: [CleaningAdjustment]) -> [AdaptiveIsolationReview] {
        var out: [AdaptiveIsolationReview] = []
        for item in items {
            let derived = newAdaptiveIsolationReview(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleAdaptiveIsolationReview(_ item: AdaptiveIsolationReview) -> String {
        return normalizeCleaningAdjustmentCode(item.code)
    }
}
