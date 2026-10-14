import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeStudyTargetsForReservation(_ items: [StudyTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func derivePrimaryReadReservationsFromTarget(_ items: [StudyTarget]) -> [PrimaryReadReservation] {
        var out: [PrimaryReadReservation] = []
        for item in items {
            let derived = newPrimaryReadReservation(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func computePrimaryReadReservation(_ item: PrimaryReadReservation) -> Double {
        return studyTargetWeight(6, active: true)
    }
}
