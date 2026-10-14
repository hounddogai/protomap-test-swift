import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierGroupsForReservation(_ items: [CourierGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveRegionalAccessionReservationsFromGroup(_ items: [CourierGroup]) -> [RegionalAccessionReservation] {
        var out: [RegionalAccessionReservation] = []
        for item in items {
            let derived = newRegionalAccessionReservation(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateRegionalAccessionReservation(_ item: RegionalAccessionReservation) -> Double {
        return courierGroupWeight(2, active: true)
    }
}
