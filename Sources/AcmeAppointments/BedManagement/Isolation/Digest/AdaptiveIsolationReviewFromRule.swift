import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCappedTransferRulesForReview(_ items: [CappedTransferRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveAdaptiveIsolationReviewsFromRule(_ items: [CappedTransferRule]) -> [AdaptiveIsolationReview] {
        var out: [AdaptiveIsolationReview] = []
        for item in items {
            let derived = newAdaptiveIsolationReview(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleAdaptiveIsolationReviewExtra(_ item: AdaptiveIsolationReview) -> String {
        return classifyAdaptiveTransferTier(item.netExposure())
    }
}
