import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFallbackEligibilityPlansForReservation(_ items: [FallbackEligibilityPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveEligibilityReservationsFromPlan(_ items: [FallbackEligibilityPlan]) -> [EligibilityReservation] {
        var out: [EligibilityReservation] = []
        for item in items {
            let derived = newEligibilityReservation(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignEligibilityReservation(_ item: EligibilityReservation) -> Double {
        return batchedEligibilityVarianceWeight(3, active: true)
    }
}
