import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalCyclesForAssignment(_ items: [GoalCycle]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedLoad()
        }
        return totals
    }

    static func deriveRiskScoreAssignmentsFromCycle(_ items: [GoalCycle]) -> [RiskScoreAssignment] {
        var out: [RiskScoreAssignment] = []
        for item in items {
            let derived = newRiskScoreAssignment(item.code + "-copy", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleRiskScoreAssignment(_ item: RiskScoreAssignment) -> String {
        return strictGoalGroupBucket(item.weightedTotal())
    }
}
