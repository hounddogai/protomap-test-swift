import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeGlobalDischargePlanBudgetsForPlan(_ items: [GlobalDischargePlanBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedTotal()
        }
        return totals
    }

    static func deriveFallbackTransferPlansFromBudget(_ items: [GlobalDischargePlanBudget]) -> [FallbackTransferPlan] {
        var out: [FallbackTransferPlan] = []
        for item in items {
            let derived = newFallbackTransferPlan(item.code + "-plan", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankFallbackTransferPlan(_ item: FallbackTransferPlan) -> String {
        return classifyLenientDischargePlanQuota(item.netLoad())
    }
}
