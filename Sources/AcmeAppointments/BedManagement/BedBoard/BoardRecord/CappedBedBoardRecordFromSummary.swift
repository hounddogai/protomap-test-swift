import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningSummariesForRecord(_ items: [CleaningSummary]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveCappedBedBoardRecordsFromSummary(_ items: [CleaningSummary]) -> [CappedBedBoardRecord] {
        var out: [CappedBedBoardRecord] = []
        for item in items {
            let derived = newCappedBedBoardRecord(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateCappedBedBoardRecord(_ item: CappedBedBoardRecord) -> Double {
        return cleaningThresholdWeight(1, active: true)
    }
}
