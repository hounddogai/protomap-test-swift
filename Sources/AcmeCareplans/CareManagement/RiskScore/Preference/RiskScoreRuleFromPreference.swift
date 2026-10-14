import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizePendingGoalPreferencesForRule(_ items: [PendingGoalPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedVolume()
        }
        return totals
    }

    static func deriveRiskScoreRulesFromPreference(_ items: [PendingGoalPreference]) -> [RiskScoreRule] {
        var out: [RiskScoreRule] = []
        for item in items {
            let derived = newRiskScoreRule(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func deriveRiskScoreRule(_ item: RiskScoreRule) -> String {
        return classifyPendingGoalPreference(item.netLoad())
    }
}
