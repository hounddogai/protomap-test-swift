import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeManualTransferGroupsForTier(_ items: [ManualTransferGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveLenientBedBoardTiersFromGroup(_ items: [ManualTransferGroup]) -> [LenientBedBoardTier] {
        var out: [LenientBedBoardTier] = []
        for item in items {
            let derived = newLenientBedBoardTier(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func estimateLenientBedBoardTier(_ item: LenientBedBoardTier) -> String {
        return seasonalTransferGroupBucket(item.effectiveLoad())
    }
}
