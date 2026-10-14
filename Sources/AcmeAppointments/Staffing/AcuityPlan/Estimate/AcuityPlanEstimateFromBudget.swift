import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeShiftBudgetsForEstimate(_ items: [ShiftBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAcuityPlanEstimatesFromBudget(_ items: [ShiftBudget]) -> [AcuityPlanEstimate] {
        var out: [AcuityPlanEstimate] = []
        for item in items {
            let derived = newAcuityPlanEstimate(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankAcuityPlanEstimate(_ item: AcuityPlanEstimate) -> String {
        return normalizeShiftSummaryCode(item.code)
    }
}
