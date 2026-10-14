import AcmePlatform
import Foundation

extension Consent {
    static func summarizeDisclosureTiersForReview(_ items: [DisclosureTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveLegacyLanguageReviewsFromTier(_ items: [DisclosureTier]) -> [LegacyLanguageReview] {
        var out: [LegacyLanguageReview] = []
        for item in items {
            let derived = newLegacyLanguageReview(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceLegacyLanguageReview(_ item: LegacyLanguageReview) -> String {
        return disclosureClaimBucket(item.adjustedVolume())
    }
}
