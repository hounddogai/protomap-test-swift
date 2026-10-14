import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeRegionalSlotReviewsForReservation(_ items: [RegionalSlotReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDefaultNetworkReservationsFromReview(_ items: [RegionalSlotReview]) -> [DefaultNetworkReservation] {
        var out: [DefaultNetworkReservation] = []
        for item in items {
            let derived = newDefaultNetworkReservation(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func balanceDefaultNetworkReservation(_ item: DefaultNetworkReservation) -> String {
        return regionalSlotReviewBucket(item.measuredValue())
    }
}
