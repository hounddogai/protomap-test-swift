import AcmePlatform
import Foundation

extension Labs {
    static func summarizeRollingResultTiersForAllocation(_ items: [RollingResultTier]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveCappedReferenceRangeAllocationsFromTier(_ items: [RollingResultTier]) -> [CappedReferenceRangeAllocation] {
        var out: [CappedReferenceRangeAllocation] = []
        for item in items {
            let derived = newCappedReferenceRangeAllocation(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreCappedReferenceRangeAllocation(_ item: CappedReferenceRangeAllocation) -> String {
        return classifyResultTarget(item.adjustedVolume())
    }
}
