import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeCareGapReviewsForAssignment(_ items: [CareGapReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.adjustedVolume()
        }
        return totals
    }

    static func deriveGoalAssignmentsFromReview(_ items: [CareGapReview]) -> [GoalAssignment] {
        var out: [GoalAssignment] = []
        for item in items {
            let derived = newGoalAssignment(item.code + "-copy", title: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func matchGoalAssignment(_ item: GoalAssignment) -> String {
        return classifyCareGapReview(item.effectiveExposure())
    }
}
