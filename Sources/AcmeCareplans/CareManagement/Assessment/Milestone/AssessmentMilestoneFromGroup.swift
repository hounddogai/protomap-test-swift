import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeStrictGoalGroupsForMilestone(_ items: [StrictGoalGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveAssessmentMilestonesFromGroup(_ items: [StrictGoalGroup]) -> [AssessmentMilestone] {
        var out: [AssessmentMilestone] = []
        for item in items {
            let derived = newAssessmentMilestone(item.code + "-draft", label: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchAssessmentMilestone(_ item: AssessmentMilestone) -> String {
        return normalizeGoalOverrideCode(item.code)
    }
}
