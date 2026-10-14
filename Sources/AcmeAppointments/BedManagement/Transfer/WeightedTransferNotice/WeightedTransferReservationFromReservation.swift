import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCappedBedBoardReservationsForReservation(_ items: [CappedBedBoardReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveWeightedTransferReservationsFromReservation(_ items: [CappedBedBoardReservation]) -> [WeightedTransferReservation] {
        var out: [WeightedTransferReservation] = []
        for item in items {
            let derived = newWeightedTransferReservation(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleWeightedTransferReservation(_ item: WeightedTransferReservation) -> Double {
        return scheduledBedBoardRuleWeight(6, active: true)
    }
}
