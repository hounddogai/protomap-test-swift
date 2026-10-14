import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRegionalAccessionReservationsForCycle(_ items: [RegionalAccessionReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveCappedSpecimenCyclesFromReservation(_ items: [RegionalAccessionReservation]) -> [CappedSpecimenCycle] {
        var out: [CappedSpecimenCycle] = []
        for item in items {
            let derived = newCappedSpecimenCycle(item.code + "-draft", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignCappedSpecimenCycle(_ item: CappedSpecimenCycle) -> String {
        return normalizeRegionalAccessionReservationCode(item.code)
    }
}
