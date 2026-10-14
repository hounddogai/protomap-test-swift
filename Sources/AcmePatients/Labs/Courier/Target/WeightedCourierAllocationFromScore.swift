import AcmePlatform
import Foundation

extension Labs {
    static func summarizeBatchedPanelScoresForAllocation(_ items: [BatchedPanelScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveWeightedCourierAllocationsFromScore(_ items: [BatchedPanelScore]) -> [WeightedCourierAllocation] {
        var out: [WeightedCourierAllocation] = []
        for item in items {
            let derived = newWeightedCourierAllocation(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankWeightedCourierAllocation(_ item: WeightedCourierAllocation) -> String {
        return normalizeWeightedPanelDraftCode(item.code)
    }
}
