import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachBudgetsForRule(_ items: [OutreachBudget]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveRiskScoreRulesFromBudget(_ items: [OutreachBudget]) -> [RiskScoreRule] {
        var out: [RiskScoreRule] = []
        for item in items {
            let derived = newRiskScoreRule(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func mergeRiskScoreRule(_ item: RiskScoreRule) -> String {
        return classifyOutreachThreshold(item.netLoad())
    }
}
