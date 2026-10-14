import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRiskScoreClaimsForProposal(_ items: [RiskScoreClaim]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGoalProposalsFromClaim(_ items: [RiskScoreClaim]) -> [GoalProposal] {
        var out: [GoalProposal] = []
        for item in items {
            let derived = newGoalProposal(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankGoalProposal(_ item: GoalProposal) -> String {
        return classifyRiskScoreBudget(item.measuredValue())
    }
}
