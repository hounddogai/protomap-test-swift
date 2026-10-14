import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusScoresForRecord(_ items: [CensusScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveValue()
        }
        return totals
    }

    static func deriveCappedBedBoardRecordsFromScore(_ items: [CensusScore]) -> [CappedBedBoardRecord] {
        var out: [CappedBedBoardRecord] = []
        for item in items {
            let derived = newCappedBedBoardRecord(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func planCappedBedBoardRecord(_ item: CappedBedBoardRecord) -> String {
        return classifyCensusWindow(item.adjustedExposure())
    }
}
