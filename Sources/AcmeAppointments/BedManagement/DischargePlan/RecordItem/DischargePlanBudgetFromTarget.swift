import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanTargetsForBudget(_ items: [DischargePlanTarget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveDischargePlanBudgetsFromTarget(_ items: [DischargePlanTarget]) -> [DischargePlanBudget] {
        var out: [DischargePlanBudget] = []
        for item in items {
            let derived = newDischargePlanBudget(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func summarizeDischargePlanBudget(_ item: DischargePlanBudget) -> String {
        return normalizeDischargePlanEstimateCode(item.code)
    }
}
