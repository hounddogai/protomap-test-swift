import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeIsolationMappingsForAllocation(_ items: [IsolationMapping]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveBatchedIsolationAllocationsFromMapping(_ items: [IsolationMapping]) -> [BatchedIsolationAllocation] {
        var out: [BatchedIsolationAllocation] = []
        for item in items {
            let derived = newBatchedIsolationAllocation(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreBatchedIsolationAllocation(_ item: BatchedIsolationAllocation) -> Double {
        return isolationMappingWeight(6, active: true)
    }
}
