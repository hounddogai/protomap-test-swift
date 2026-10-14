import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeTieredPriorityReservationsForReservation(_ items: [TieredPriorityReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func derivePendingWorklistReservationsFromReservation(_ items: [TieredPriorityReservation]) -> [PendingWorklistReservation] {
        var out: [PendingWorklistReservation] = []
        for item in items {
            let derived = newPendingWorklistReservation(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankPendingWorklistReservation(_ item: PendingWorklistReservation) -> String {
        return normalizePriorityEntryCode(item.code)
    }
}
