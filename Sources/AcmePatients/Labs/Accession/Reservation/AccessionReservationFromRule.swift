import AcmePlatform
import Foundation

extension Labs {
    static func summarizeSpecimenRulesForReservation(_ items: [SpecimenRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveAccessionReservationsFromRule(_ items: [SpecimenRule]) -> [AccessionReservation] {
        var out: [AccessionReservation] = []
        for item in items {
            let derived = newAccessionReservation(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func summarizeAccessionReservation(_ item: AccessionReservation) -> Double {
        return specimenGroupWeight(2, active: true)
    }
}
