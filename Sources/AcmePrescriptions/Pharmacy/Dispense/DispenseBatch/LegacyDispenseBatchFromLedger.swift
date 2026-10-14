import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePendingRecallLedgersForBatch(_ items: [PendingRecallLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveLegacyDispenseBatchesFromLedger(_ items: [PendingRecallLedger]) -> [LegacyDispenseBatch] {
        var out: [LegacyDispenseBatch] = []
        for item in items {
            let derived = newLegacyDispenseBatch(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignLegacyDispenseBatch(_ item: LegacyDispenseBatch) -> String {
        return normalizePendingRecallLedgerCode(item.code)
    }
}
