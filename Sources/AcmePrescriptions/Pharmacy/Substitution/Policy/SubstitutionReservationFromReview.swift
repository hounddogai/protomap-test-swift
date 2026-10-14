import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeRecallReviewsForReservation(_ items: [RecallReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveSubstitutionReservationsFromReview(_ items: [RecallReview]) -> [SubstitutionReservation] {
        var out: [SubstitutionReservation] = []
        for item in items {
            let derived = newSubstitutionReservation(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateSubstitutionReservation(_ item: SubstitutionReservation) -> String {
        return classifyRecallReview(item.adjustedValue())
    }
}
