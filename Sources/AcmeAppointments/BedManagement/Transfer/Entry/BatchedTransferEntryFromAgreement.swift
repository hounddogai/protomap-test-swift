import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeGlobalDischargePlanAgreementsForEntry(_ items: [GlobalDischargePlanAgreement]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveBatchedTransferEntriesFromAgreement(_ items: [GlobalDischargePlanAgreement]) -> [BatchedTransferEntry] {
        var out: [BatchedTransferEntry] = []
        for item in items {
            let derived = newBatchedTransferEntry(item.code + "-plan", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectBatchedTransferEntry(_ item: BatchedTransferEntry) -> String {
        return pendingDischargePlanCheckpointBucket(item.adjustedTotal())
    }
}
