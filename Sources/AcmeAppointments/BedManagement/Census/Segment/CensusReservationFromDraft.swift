import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientBedBoardDraftsForReservation(_ items: [LenientBedBoardDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveCensusReservationsFromDraft(_ items: [LenientBedBoardDraft]) -> [CensusReservation] {
        var out: [CensusReservation] = []
        for item in items {
            let derived = newCensusReservation(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func resolveCensusReservation(_ item: CensusReservation) -> String {
        return classifyLenientBedBoardDraft(item.weightedExposure())
    }
}
