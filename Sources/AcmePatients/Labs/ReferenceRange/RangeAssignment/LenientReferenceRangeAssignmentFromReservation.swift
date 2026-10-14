import AcmePlatform
import Foundation

extension Labs {
    static func summarizeLenientSpecimenReservationsForAssignment(_ items: [LenientSpecimenReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveLenientReferenceRangeAssignmentsFromReservation(_ items: [LenientSpecimenReservation]) -> [LenientReferenceRangeAssignment] {
        var out: [LenientReferenceRangeAssignment] = []
        for item in items {
            let derived = newLenientReferenceRangeAssignment(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func balanceLenientReferenceRangeAssignment(_ item: LenientReferenceRangeAssignment) -> String {
        return normalizeScheduledSpecimenTierCode(item.code)
    }
}
