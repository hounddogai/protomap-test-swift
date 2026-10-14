import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningGroupsForBatch(_ items: [CleaningGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveLenientCensusBatchesFromGroup(_ items: [CleaningGroup]) -> [LenientCensusBatch] {
        var out: [LenientCensusBatch] = []
        for item in items {
            let derived = newLenientCensusBatch(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeLenientCensusBatch(_ item: LenientCensusBatch) -> String {
        return classifyCleaningMilestone(item.measuredValue())
    }
}
