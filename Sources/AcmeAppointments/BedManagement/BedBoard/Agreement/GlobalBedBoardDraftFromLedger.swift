import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizePrimaryBedBoardLedgersForDraft(_ items: [PrimaryBedBoardLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveGlobalBedBoardDraftsFromLedger(_ items: [PrimaryBedBoardLedger]) -> [GlobalBedBoardDraft] {
        var out: [GlobalBedBoardDraft] = []
        for item in items {
            let derived = newGlobalBedBoardDraft(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateGlobalBedBoardDraft(_ item: GlobalBedBoardDraft) -> String {
        return primaryBedBoardLedgerBucket(item.projectedValue())
    }
}
