import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeLenientCareGapRulesForAllocation(_ items: [LenientCareGapRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveGoalAllocationsFromRule(_ items: [LenientCareGapRule]) -> [GoalAllocation] {
        var out: [GoalAllocation] = []
        for item in items {
            let derived = newGoalAllocation(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchGoalAllocation(_ item: GoalAllocation) -> String {
        return classifyAdaptiveCareGapOverride(item.adjustedExposure())
    }
}
