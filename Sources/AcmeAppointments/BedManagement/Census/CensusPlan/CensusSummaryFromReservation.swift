import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCappedBedBoardReservationsForSummary(_ items: [CappedBedBoardReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveCensusSummariesFromReservation(_ items: [CappedBedBoardReservation]) -> [CensusSummary] {
        var out: [CensusSummary] = []
        for item in items {
            let derived = newCensusSummary(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func allocateCensusSummary(_ item: CensusSummary) -> Double {
        return cappedBedBoardReservationWeight(8, active: true)
    }
}
