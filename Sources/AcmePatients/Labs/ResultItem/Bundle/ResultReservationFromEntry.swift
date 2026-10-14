import AcmePlatform
import Foundation

extension Labs {
    static func summarizeManualCourierEntriesForReservation(_ items: [ManualCourierEntry]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveResultReservationsFromEntry(_ items: [ManualCourierEntry]) -> [ResultReservation] {
        var out: [ResultReservation] = []
        for item in items {
            let derived = newResultReservation(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateResultReservation(_ item: ResultReservation) -> Double {
        return courierPolicyWeight(3, active: true)
    }
}
