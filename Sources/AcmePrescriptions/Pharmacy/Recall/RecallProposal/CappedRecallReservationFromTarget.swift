import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeGlobalSubstitutionTargetsForReservation(_ items: [GlobalSubstitutionTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveCappedRecallReservationsFromTarget(_ items: [GlobalSubstitutionTarget]) -> [CappedRecallReservation] {
        var out: [CappedRecallReservation] = []
        for item in items {
            let derived = newCappedRecallReservation(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleCappedRecallReservation(_ item: CappedRecallReservation) -> String {
        return normalizeGlobalSubstitutionTargetCode(item.code)
    }
}
