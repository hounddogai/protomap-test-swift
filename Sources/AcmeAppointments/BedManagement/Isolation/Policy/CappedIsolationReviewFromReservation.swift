import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDefaultCleaningReservationsForReview(_ items: [DefaultCleaningReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveCappedIsolationReviewsFromReservation(_ items: [DefaultCleaningReservation]) -> [CappedIsolationReview] {
        var out: [CappedIsolationReview] = []
        for item in items {
            let derived = newCappedIsolationReview(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankCappedIsolationReview(_ item: CappedIsolationReview) -> String {
        return normalizeDefaultCleaningReservationCode(item.code)
    }
}
