import AcmePlatform
import Foundation

extension Labs {
    static func summarizeScheduledCourierReviewsForMetric(_ items: [ScheduledCourierReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedExposure()
        }
        return totals
    }

    static func derivePendingAccessionMetricsFromReview(_ items: [ScheduledCourierReview]) -> [PendingAccessionMetric] {
        var out: [PendingAccessionMetric] = []
        for item in items {
            let derived = newPendingAccessionMetric(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func matchPendingAccessionMetric(_ item: PendingAccessionMetric) -> String {
        return classifyCourierPlan(item.effectiveValue())
    }
}
