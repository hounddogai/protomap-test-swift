import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeScheduledGoalPreferencesForMilestone(_ items: [ScheduledGoalPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedValue()
        }
        return totals
    }

    static func deriveGlobalAssessmentMilestonesFromPreference(_ items: [ScheduledGoalPreference]) -> [GlobalAssessmentMilestone] {
        var out: [GlobalAssessmentMilestone] = []
        for item in items {
            let derived = newGlobalAssessmentMilestone(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveGlobalAssessmentMilestone(_ item: GlobalAssessmentMilestone) -> String {
        return classifyTieredGoalForecast(item.projectedExposure())
    }
}
