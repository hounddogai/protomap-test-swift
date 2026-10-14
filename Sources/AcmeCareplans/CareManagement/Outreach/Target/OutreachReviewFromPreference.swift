import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGoalPreferencesForReview(_ items: [GoalPreference]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.measuredValue()
        }
        return totals
    }

    static func deriveOutreachReviewsFromPreference(_ items: [GoalPreference]) -> [OutreachReview] {
        var out: [OutreachReview] = []
        for item in items {
            let derived = newOutreachReview(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileOutreachReview(_ item: OutreachReview) -> String {
        return normalizeGoalSegmentCode(item.code)
    }
}
