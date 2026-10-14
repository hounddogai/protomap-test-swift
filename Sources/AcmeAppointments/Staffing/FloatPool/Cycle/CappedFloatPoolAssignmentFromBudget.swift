import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeSeasonalAcuityPlanBudgetsForAssignment(_ items: [SeasonalAcuityPlanBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveCappedFloatPoolAssignmentsFromBudget(_ items: [SeasonalAcuityPlanBudget]) -> [CappedFloatPoolAssignment] {
        var out: [CappedFloatPoolAssignment] = []
        for item in items {
            let derived = newCappedFloatPoolAssignment(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignCappedFloatPoolAssignment(_ item: CappedFloatPoolAssignment) -> String {
        return classifySeasonalAcuityPlanBudget(item.weightedExposure())
    }
}
