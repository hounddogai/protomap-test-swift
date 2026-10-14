import AcmePlatform
import Foundation

extension Labs {
    static func summarizeReferenceRangeLedgersForAllocation(_ items: [ReferenceRangeLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveResultAllocationsFromLedger(_ items: [ReferenceRangeLedger]) -> [ResultAllocation] {
        var out: [ResultAllocation] = []
        for item in items {
            let derived = newResultAllocation(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveResultAllocation(_ item: ResultAllocation) -> String {
        return scheduledReferenceRangeRuleBucket(item.projectedTotal())
    }
}
