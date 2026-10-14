import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeGlobalShiftAllocationsForBudget(_ items: [GlobalShiftAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveFloatPoolBudgetsFromAllocation(_ items: [GlobalShiftAllocation]) -> [FloatPoolBudget] {
        var out: [FloatPoolBudget] = []
        for item in items {
            let derived = newFloatPoolBudget(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func applyFloatPoolBudget(_ item: FloatPoolBudget) -> String {
        return globalShiftAllocationBucket(item.effectiveTotal())
    }
}
