import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeWeightedAcuityPlanBudgetsForSchedule(_ items: [WeightedAcuityPlanBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func deriveAcuityPlanSchedulesFromBudget(_ items: [WeightedAcuityPlanBudget]) -> [AcuityPlanSchedule] {
        var out: [AcuityPlanSchedule] = []
        for item in items {
            let derived = newAcuityPlanSchedule(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyAcuityPlanScheduleExtra(_ item: AcuityPlanSchedule) -> String {
        return normalizeWeightedAcuityPlanBudgetCode(item.code)
    }
}
