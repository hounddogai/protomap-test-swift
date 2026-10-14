import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeBedBoardSlotsForEntry(_ items: [BedBoardSlot]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveCleaningEntriesFromSlot(_ items: [BedBoardSlot]) -> [CleaningEntry] {
        var out: [CleaningEntry] = []
        for item in items {
            let derived = newCleaningEntry(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateCleaningEntry(_ item: CleaningEntry) -> String {
        return bedBoardRollupBucket(item.projectedVolume())
    }
}
