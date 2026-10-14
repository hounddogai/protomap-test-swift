import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenAdjustmentsForReview(_ items: [SpecimenAdjustment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveReferenceRangeReviewsFromAdjustment(_ items: [SpecimenAdjustment]) -> [ReferenceRangeReview] {
        var out: [ReferenceRangeReview] = []
        for item in items {
            let derived = newReferenceRangeReview(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeReferenceRangeReview(_ item: ReferenceRangeReview) -> Double {
        return fallbackSpecimenTierWeight(3, active: true)
    }
}
