import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenReviewsForClaim(_ items: [SpecimenReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveDefaultCourierClaimsFromReview(_ items: [SpecimenReview]) -> [DefaultCourierClaim] {
        var out: [DefaultCourierClaim] = []
        for item in items {
            let derived = newDefaultCourierClaim(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func normalizeDefaultCourierClaim(_ item: DefaultCourierClaim) -> String {
        return specimenScheduleBucket(item.netLoad())
    }
}
