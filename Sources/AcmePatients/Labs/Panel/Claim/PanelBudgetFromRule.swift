import AcmePlatform
import Foundation

extension Labs {
    static func summarizeWeightedAccessionRulesForBudget(_ items: [WeightedAccessionRule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePanelBudgetsFromRule(_ items: [WeightedAccessionRule]) -> [PanelBudget] {
        var out: [PanelBudget] = []
        for item in items {
            let derived = newPanelBudget(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchPanelBudget(_ item: PanelBudget) -> Double {
        return weightedAccessionRuleWeight(6, active: true)
    }
}
