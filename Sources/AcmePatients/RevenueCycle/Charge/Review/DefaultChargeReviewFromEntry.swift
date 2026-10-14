import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeCappedChargeEntriesForReview(_ items: [CappedChargeEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveDefaultChargeReviewsFromEntry(_ items: [CappedChargeEntry]) -> [DefaultChargeReview] {
        var out: [DefaultChargeReview] = []
        for item in items {
            let derived = newDefaultChargeReview(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func normalizeDefaultChargeReview(_ item: DefaultChargeReview) -> String {
        return normalizeChargeProposalCode(item.code)
    }
}
