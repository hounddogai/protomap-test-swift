import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeCensusBudgetsForSummary(_ items: [CensusBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveDischargePlanSummariesFromBudget(_ items: [CensusBudget]) -> [DischargePlanSummary] {
        var out: [DischargePlanSummary] = []
        for item in items {
            let derived = newDischargePlanSummary(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeDischargePlanSummary(_ item: DischargePlanSummary) -> Double {
        return censusBudgetWeight(7, active: true)
    }
}
