import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalScoresForSchedule(_ items: [GoalScore]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveOutreachSchedulesFromScore(_ items: [GoalScore]) -> [OutreachSchedule] {
        var out: [OutreachSchedule] = []
        for item in items {
            let derived = newOutreachSchedule(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileOutreachSchedule(_ item: OutreachSchedule) -> String {
        return classifyGoalScore(item.adjustedExposure())
    }
}
