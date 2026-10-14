import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachCheckpointsForScore(_ items: [OutreachCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveGoalScoresFromCheckpoint(_ items: [OutreachCheckpoint]) -> [GoalScore] {
        var out: [GoalScore] = []
        for item in items {
            let derived = newGoalScore(item.code + "-plan", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func rankGoalScore(_ item: GoalScore) -> Double {
        return outreachCheckpointWeight(7, active: true)
    }
}
