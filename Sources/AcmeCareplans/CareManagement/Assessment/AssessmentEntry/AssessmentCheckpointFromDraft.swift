import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalDraftsForCheckpoint(_ items: [GoalDraft]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveAssessmentCheckpointsFromDraft(_ items: [GoalDraft]) -> [AssessmentCheckpoint] {
        var out: [AssessmentCheckpoint] = []
        for item in items {
            let derived = newAssessmentCheckpoint(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func classifyAssessmentCheckpointExtra(_ item: AssessmentCheckpoint) -> Double {
        return goalDigestWeight(5, active: true)
    }
}
