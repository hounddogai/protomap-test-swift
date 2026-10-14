import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalAssignmentsForAssignment(_ items: [GoalAssignment]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveExposure()
        }
        return totals
    }

    static func deriveOutreachAssignmentsFromAssignment(_ items: [GoalAssignment]) -> [OutreachAssignment] {
        var out: [OutreachAssignment] = []
        for item in items {
            let derived = newOutreachAssignment(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func estimateOutreachAssignment(_ item: OutreachAssignment) -> String {
        return goalAssignmentBucket(item.weightedExposure())
    }
}
