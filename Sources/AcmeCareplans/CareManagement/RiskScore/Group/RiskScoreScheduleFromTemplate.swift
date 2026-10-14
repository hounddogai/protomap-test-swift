import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeRollingGoalTemplatesForSchedule(_ items: [RollingGoalTemplate]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveRiskScoreSchedulesFromTemplate(_ items: [RollingGoalTemplate]) -> [RiskScoreSchedule] {
        var out: [RiskScoreSchedule] = []
        for item in items {
            let derived = newRiskScoreSchedule(item.code + "-copy", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func projectRiskScoreSchedule(_ item: RiskScoreSchedule) -> Double {
        return defaultGoalSegmentWeight(1, active: true)
    }
}
