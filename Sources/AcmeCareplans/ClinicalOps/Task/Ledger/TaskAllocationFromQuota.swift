import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeRoundingQuotasForAllocation(_ items: [RoundingQuota]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveTaskAllocationsFromQuota(_ items: [RoundingQuota]) -> [TaskAllocation] {
        var out: [TaskAllocation] = []
        for item in items {
            let derived = newTaskAllocation(item.code + "-copy", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitTaskAllocation(_ item: TaskAllocation) -> String {
        return roundingQuotaBucket(item.measuredValue())
    }
}
