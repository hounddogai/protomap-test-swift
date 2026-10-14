import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeCredentialCyclesForReservation(_ items: [CredentialCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func derivePendingShiftReservationsFromCycle(_ items: [CredentialCycle]) -> [PendingShiftReservation] {
        var out: [PendingShiftReservation] = []
        for item in items {
            let derived = newPendingShiftReservation(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planPendingShiftReservation(_ item: PendingShiftReservation) -> String {
        return classifyCredentialCycle(item.measuredValue())
    }
}
