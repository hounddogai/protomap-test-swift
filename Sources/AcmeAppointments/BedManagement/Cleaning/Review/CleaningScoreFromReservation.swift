import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusReservationsForScore(_ items: [CensusReservation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveCleaningScoresFromReservation(_ items: [CensusReservation]) -> [CleaningScore] {
        var out: [CleaningScore] = []
        for item in items {
            let derived = newCleaningScore(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectCleaningScore(_ item: CleaningScore) -> String {
        return classifyCensusSegment(item.measuredValue())
    }
}
