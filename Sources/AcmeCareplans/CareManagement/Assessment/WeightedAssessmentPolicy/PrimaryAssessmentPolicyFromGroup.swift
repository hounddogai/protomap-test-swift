import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGlobalGoalGroupsForPolicy(_ items: [GlobalGoalGroup]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func derivePrimaryAssessmentPoliciesFromGroup(_ items: [GlobalGoalGroup]) -> [PrimaryAssessmentPolicy] {
        var out: [PrimaryAssessmentPolicy] = []
        for item in items {
            let derived = newPrimaryAssessmentPolicy(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func balancePrimaryAssessmentPolicy(_ item: PrimaryAssessmentPolicy) -> String {
        return classifyPendingGoalSchedule(item.netValue())
    }
}
