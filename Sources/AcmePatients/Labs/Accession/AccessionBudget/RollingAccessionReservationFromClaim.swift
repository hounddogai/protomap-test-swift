import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeClaimsForReservation(_ items: [ReferenceRangeClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveRollingAccessionReservationsFromClaim(_ items: [ReferenceRangeClaim]) -> [RollingAccessionReservation] {
        var out: [RollingAccessionReservation] = []
        for item in items {
            let derived = newRollingAccessionReservation(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectRollingAccessionReservation(_ item: RollingAccessionReservation) -> String {
        return normalizeReferenceRangeAdjustmentCode(item.code)
    }
}
