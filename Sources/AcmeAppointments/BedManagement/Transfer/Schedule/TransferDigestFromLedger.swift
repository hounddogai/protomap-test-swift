import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeRegionalCleaningLedgersForDigest(_ items: [RegionalCleaningLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveTransferDigestsFromLedger(_ items: [RegionalCleaningLedger]) -> [TransferDigest] {
        var out: [TransferDigest] = []
        for item in items {
            let derived = newTransferDigest(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileTransferDigest(_ item: TransferDigest) -> String {
        return classifyRegionalCleaningLedger(item.weightedTotal())
    }
}
