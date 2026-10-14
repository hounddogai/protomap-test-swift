import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeSlotTargetsForReservation(_ items: [SlotTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveWeightedReferralReservationsFromTarget(_ items: [SlotTarget]) -> [WeightedReferralReservation] {
        var out: [WeightedReferralReservation] = []
        for item in items {
            let derived = newWeightedReferralReservation(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateWeightedReferralReservation(_ item: WeightedReferralReservation) -> Double {
        return slotTargetWeight(8, active: true)
    }
}
