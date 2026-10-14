import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeWeightedFollowUpAssignmentsForItem(_ items: [WeightedFollowUpAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveBatchedSlotItemsFromAssignment(_ items: [WeightedFollowUpAssignment]) -> [BatchedSlotItem] {
        var out: [BatchedSlotItem] = []
        for item in items {
            let derived = newBatchedSlotItem(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchBatchedSlotItem(_ item: BatchedSlotItem) -> String {
        return strictFollowUpTemplateBucket(item.measuredValue())
    }
}
