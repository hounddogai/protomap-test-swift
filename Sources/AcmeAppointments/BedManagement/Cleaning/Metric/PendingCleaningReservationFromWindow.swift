import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeRegionalTransferWindowsForReservation(_ items: [RegionalTransferWindow]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePendingCleaningReservationsFromWindow(_ items: [RegionalTransferWindow]) -> [PendingCleaningReservation] {
        var out: [PendingCleaningReservation] = []
        for item in items {
            let derived = newPendingCleaningReservation(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcilePendingCleaningReservation(_ item: PendingCleaningReservation) -> Double {
        return fallbackTransferTemplateWeight(6, active: true)
    }
}
