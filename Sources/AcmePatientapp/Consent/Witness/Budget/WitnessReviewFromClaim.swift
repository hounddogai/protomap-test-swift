import AcmePlatform
import Foundation

extension Consent {
    static func summarizeFallbackLanguageClaimsForReview(_ items: [FallbackLanguageClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveWitnessReviewsFromClaim(_ items: [FallbackLanguageClaim]) -> [WitnessReview] {
        var out: [WitnessReview] = []
        for item in items {
            let derived = newWitnessReview(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignWitnessReview(_ item: WitnessReview) -> String {
        return normalizePrimaryLanguageAssignmentCode(item.code)
    }
}
