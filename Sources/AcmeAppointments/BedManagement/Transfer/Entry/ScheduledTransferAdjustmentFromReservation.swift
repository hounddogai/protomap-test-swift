import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeWeightedTransferReservationsForAdjustment(_ items: [WeightedTransferReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveScheduledTransferAdjustmentsFromReservation(_ items: [WeightedTransferReservation]) -> [ScheduledTransferAdjustment] {
        var out: [ScheduledTransferAdjustment] = []
        for item in items {
            let derived = newScheduledTransferAdjustment(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileScheduledTransferAdjustment(_ item: ScheduledTransferAdjustment) -> String {
        return weightedTransferReservationBucket(item.weightedLoad())
    }
}
