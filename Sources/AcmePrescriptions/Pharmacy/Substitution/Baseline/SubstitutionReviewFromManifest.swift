import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeLenientInventoryManifestsForReview(_ items: [LenientInventoryManifest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveSubstitutionReviewsFromManifest(_ items: [LenientInventoryManifest]) -> [SubstitutionReview] {
        var out: [SubstitutionReview] = []
        for item in items {
            let derived = newSubstitutionReview(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveSubstitutionReview(_ item: SubstitutionReview) -> String {
        return normalizeInventoryReservationCode(item.code)
    }
}
