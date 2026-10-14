import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalEstimatesForProposal(_ items: [GoalEstimate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGoalProposalsFromEstimate(_ items: [GoalEstimate]) -> [GoalProposal] {
        var out: [GoalProposal] = []
        for item in items {
            let derived = newGoalProposal(item.code + "-next", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func rankGoalProposalExtra(_ item: GoalProposal) -> String {
        return pendingGoalPreferenceBucket(item.measuredValue())
    }
}
