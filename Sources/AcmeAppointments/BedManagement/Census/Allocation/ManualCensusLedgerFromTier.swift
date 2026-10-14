import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeLenientBedBoardTiersForLedger(_ items: [LenientBedBoardTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveManualCensusLedgersFromTier(_ items: [LenientBedBoardTier]) -> [ManualCensusLedger] {
        var out: [ManualCensusLedger] = []
        for item in items {
            let derived = newManualCensusLedger(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleManualCensusLedger(_ item: ManualCensusLedger) -> String {
        return lenientBedBoardTierBucket(item.weightedTotal())
    }
}
