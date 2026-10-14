import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeScheduledGoalCheckpointsForWindow(_ items: [ScheduledGoalCheckpoint]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedLoad()
        }
        return totals
    }

    static func deriveAssessmentWindowsFromCheckpoint(_ items: [ScheduledGoalCheckpoint]) -> [AssessmentWindow] {
        var out: [AssessmentWindow] = []
        for item in items {
            let derived = newAssessmentWindow(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func resolveAssessmentWindow(_ item: AssessmentWindow) -> String {
        return classifyScheduledGoalSegment(item.weightedLoad())
    }
}
