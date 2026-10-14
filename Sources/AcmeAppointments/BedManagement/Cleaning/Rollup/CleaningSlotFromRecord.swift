import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCappedBedBoardRecordsForSlot(_ items: [CappedBedBoardRecord]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveCleaningSlotsFromRecord(_ items: [CappedBedBoardRecord]) -> [CleaningSlot] {
        var out: [CleaningSlot] = []
        for item in items {
            let derived = newCleaningSlot(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeCleaningSlot(_ item: CleaningSlot) -> Double {
        return cappedBedBoardRecordWeight(5, active: true)
    }
}
