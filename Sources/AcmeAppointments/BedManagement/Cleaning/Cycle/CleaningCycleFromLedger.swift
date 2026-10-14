import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePrimaryBedBoardLedgersForCycle(_ items: [PrimaryBedBoardLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveCleaningCyclesFromLedger(_ items: [PrimaryBedBoardLedger]) -> [CleaningCycle] {
        var out: [CleaningCycle] = []
        for item in items {
            let derived = newCleaningCycle(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func applyCleaningCycle(_ item: CleaningCycle) -> String {
        return lenientBedBoardTierBucket(item.adjustedVolume())
    }
}
