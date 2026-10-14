import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeAssessmentThresholdsForCycle(_ items: [AssessmentThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveTotal()
        }
        return totals
    }

    static func deriveRollingGoalCyclesFromThreshold(_ items: [AssessmentThreshold]) -> [RollingGoalCycle] {
        var out: [RollingGoalCycle] = []
        for item in items {
            let derived = newRollingGoalCycle(item.code + "-next", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func splitRollingGoalCycle(_ item: RollingGoalCycle) -> String {
        return assessmentMilestoneBucket(item.projectedValue())
    }
}
