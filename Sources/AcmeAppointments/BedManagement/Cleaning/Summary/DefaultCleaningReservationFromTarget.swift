import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeFallbackBedBoardTargetsForReservation(_ items: [FallbackBedBoardTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveDefaultCleaningReservationsFromTarget(_ items: [FallbackBedBoardTarget]) -> [DefaultCleaningReservation] {
        var out: [DefaultCleaningReservation] = []
        for item in items {
            let derived = newDefaultCleaningReservation(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func allocateDefaultCleaningReservation(_ item: DefaultCleaningReservation) -> String {
        return bedBoardScoreBucket(item.effectiveExposure())
    }
}
