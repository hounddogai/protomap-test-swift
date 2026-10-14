import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCappedBedBoardGroupsForEntry(_ items: [CappedBedBoardGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveRollingCleaningEntriesFromGroup(_ items: [CappedBedBoardGroup]) -> [RollingCleaningEntry] {
        var out: [RollingCleaningEntry] = []
        for item in items {
            let derived = newRollingCleaningEntry(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyRollingCleaningEntry(_ item: RollingCleaningEntry) -> String {
        return classifyCappedBedBoardGroup(item.effectiveLoad())
    }
}
