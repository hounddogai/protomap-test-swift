import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCleaningBudgetsForScore(_ items: [CleaningBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func deriveDischargePlanScoresFromBudget(_ items: [CleaningBudget]) -> [DischargePlanScore] {
        var out: [DischargePlanScore] = []
        for item in items {
            let derived = newDischargePlanScore(item.code + "-plan", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeDischargePlanScoreExtra(_ item: DischargePlanScore) -> Double {
        return cleaningBudgetWeight(9, active: true)
    }
}
