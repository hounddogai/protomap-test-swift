import AcmePlatform
import Foundation

extension Staffing {
    static func summarizeWeightedAcuityPlanBudgetsForAgreement(_ items: [WeightedAcuityPlanBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedTotal()
        }
        return totals
    }

    static func derivePendingOvertimeAgreementsFromBudget(_ items: [WeightedAcuityPlanBudget]) -> [PendingOvertimeAgreement] {
        var out: [PendingOvertimeAgreement] = []
        for item in items {
            let derived = newPendingOvertimeAgreement(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankPendingOvertimeAgreement(_ item: PendingOvertimeAgreement) -> String {
        return normalizeWeightedAcuityPlanBudgetCode(item.code)
    }
}
