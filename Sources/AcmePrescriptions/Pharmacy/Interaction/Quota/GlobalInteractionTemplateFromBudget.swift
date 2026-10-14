import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizeGlobalInteractionBudgetsForTemplate(_ items: [GlobalInteractionBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveGlobalInteractionTemplatesFromBudget(_ items: [GlobalInteractionBudget]) -> [GlobalInteractionTemplate] {
        var out: [GlobalInteractionTemplate] = []
        for item in items {
            let derived = newGlobalInteractionTemplate(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func projectGlobalInteractionTemplate(_ item: GlobalInteractionTemplate) -> Double {
        return globalInteractionBudgetWeight(5, active: true)
    }
}
