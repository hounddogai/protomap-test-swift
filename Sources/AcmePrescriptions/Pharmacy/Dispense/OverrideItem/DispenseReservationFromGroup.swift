import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeFormularyGroupsForReservation(_ items: [FormularyGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveDispenseReservationsFromGroup(_ items: [FormularyGroup]) -> [DispenseReservation] {
        var out: [DispenseReservation] = []
        for item in items {
            let derived = newDispenseReservation(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectDispenseReservation(_ item: DispenseReservation) -> Double {
        return formularyVarianceWeight(6, active: true)
    }
}
