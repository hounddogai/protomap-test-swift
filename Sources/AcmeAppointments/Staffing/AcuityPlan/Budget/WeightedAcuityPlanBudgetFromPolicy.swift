import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeScheduledFloatPoolPoliciesForBudget(_ items: [ScheduledFloatPoolPolicy]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedValue()
        }
        return totals
    }

    static func deriveWeightedAcuityPlanBudgetsFromPolicy(_ items: [ScheduledFloatPoolPolicy]) -> [WeightedAcuityPlanBudget] {
        var out: [WeightedAcuityPlanBudget] = []
        for item in items {
            let derived = newWeightedAcuityPlanBudget(item.code + "-next", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func assignWeightedAcuityPlanBudget(_ item: WeightedAcuityPlanBudget) -> String {
        return classifyFallbackFloatPoolSchedule(item.adjustedTotal())
    }
}
