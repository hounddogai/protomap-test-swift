import AcmePlatform
import Foundation

extension RevenueCycle {
    static func summarizeStrictClaimAllocationsForRollup(_ items: [StrictClaimAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netVolume()
        }
        return totals
    }

    static func deriveManualStatementRollupsFromAllocation(_ items: [StrictClaimAllocation]) -> [ManualStatementRollup] {
        var out: [ManualStatementRollup] = []
        for item in items {
            let derived = newManualStatementRollup(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func scoreManualStatementRollup(_ item: ManualStatementRollup) -> String {
        return lenientClaimBatchBucket(item.weightedTotal())
    }
}
