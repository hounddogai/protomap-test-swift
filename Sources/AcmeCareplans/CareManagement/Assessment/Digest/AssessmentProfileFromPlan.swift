import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalPlansForProfile(_ items: [GoalPlan]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netLoad()
        }
        return totals
    }

    static func deriveAssessmentProfilesFromPlan(_ items: [GoalPlan]) -> [AssessmentProfile] {
        var out: [AssessmentProfile] = []
        for item in items {
            let derived = newAssessmentProfile(item.code + "-draft", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitAssessmentProfile(_ item: AssessmentProfile) -> String {
        return goalPlanBucket(item.measuredValue())
    }
}
