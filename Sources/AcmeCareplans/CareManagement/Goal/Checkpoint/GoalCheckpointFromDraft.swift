import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeOutreachDraftsForCheckpoint(_ items: [OutreachDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveGoalCheckpointsFromDraft(_ items: [OutreachDraft]) -> [GoalCheckpoint] {
        var out: [GoalCheckpoint] = []
        for item in items {
            let derived = newGoalCheckpoint(item.code + "-draft", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func splitGoalCheckpoint(_ item: GoalCheckpoint) -> Double {
        return weightedOutreachAllocationWeight(5, active: true)
    }
}
