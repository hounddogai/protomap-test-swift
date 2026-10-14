import AcmePlatform
import Foundation

extension BedManagement {
    static func summarizeDischargePlanBudgetsForThreshold(_ items: [DischargePlanBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedExposure()
        }
        return totals
    }

    static func deriveDischargePlanThresholdsFromBudget(_ items: [DischargePlanBudget]) -> [DischargePlanThreshold] {
        var out: [DischargePlanThreshold] = []
        for item in items {
            let derived = newDischargePlanThreshold(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func scoreDischargePlanThreshold(_ item: DischargePlanThreshold) -> String {
        return normalizeDischargePlanTemplateCode(item.code)
    }
}
