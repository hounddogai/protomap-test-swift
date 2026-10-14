import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizeTaskOverridesForException(_ items: [TaskOverride]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveBatchedOrderSetExceptionsFromOverride(_ items: [TaskOverride]) -> [BatchedOrderSetException] {
        var out: [BatchedOrderSetException] = []
        for item in items {
            let derived = newBatchedOrderSetException(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileBatchedOrderSetException(_ item: BatchedOrderSetException) -> String {
        return normalizeBatchedTaskPlanCode(item.code)
    }
}
