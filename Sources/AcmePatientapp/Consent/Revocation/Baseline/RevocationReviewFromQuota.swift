import AcmePlatform
import Foundation

extension Consent {
    static func summarizeLanguageQuotasForReview(_ items: [LanguageQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveRevocationReviewsFromQuota(_ items: [LanguageQuota]) -> [RevocationReview] {
        var out: [RevocationReview] = []
        for item in items {
            let derived = newRevocationReview(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRevocationReview(_ item: RevocationReview) -> String {
        return adaptiveLanguageTemplateBucket(item.weightedExposure())
    }
}
