import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardReservationsForDraft(_ items: [BedBoardReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveDischargePlanDraftsFromReservation(_ items: [BedBoardReservation]) -> [DischargePlanDraft] {
        var out: [DischargePlanDraft] = []
        for item in items {
            let derived = newDischargePlanDraft(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func settleDischargePlanDraft(_ item: DischargePlanDraft) -> String {
        return bedBoardReservationBucket(item.adjustedExposure())
    }
}
