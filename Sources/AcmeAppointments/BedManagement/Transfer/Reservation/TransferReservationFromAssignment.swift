import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeTransferAssignmentsForReservation(_ items: [TransferAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveTransferReservationsFromAssignment(_ items: [TransferAssignment]) -> [TransferReservation] {
        var out: [TransferReservation] = []
        for item in items {
            let derived = newTransferReservation(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func deriveTransferReservation(_ item: TransferReservation) -> Double {
        return transferPreferenceWeight(3, active: true)
    }
}
