import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalRollupsForBaseline(_ items: [GoalRollup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveCappedAssessmentBaselinesFromRollup(_ items: [GoalRollup]) -> [CappedAssessmentBaseline] {
        var out: [CappedAssessmentBaseline] = []
        for item in items {
            let derived = newCappedAssessmentBaseline(item.code + "-draft", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planCappedAssessmentBaseline(_ item: CappedAssessmentBaseline) -> Double {
        return rollingGoalBatchWeight(7, active: true)
    }
}
