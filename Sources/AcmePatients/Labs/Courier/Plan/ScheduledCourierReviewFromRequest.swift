import AcmePlatform
import Foundation

extension Labs {
    static func summarizeDefaultSpecimenRequestsForReview(_ items: [DefaultSpecimenRequest]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.effectiveLoad()
        }
        return totals
    }

    static func deriveScheduledCourierReviewsFromRequest(_ items: [DefaultSpecimenRequest]) -> [ScheduledCourierReview] {
        var out: [ScheduledCourierReview] = []
        for item in items {
            let derived = newScheduledCourierReview(item.code + "-next", name: item.label())
            out.append(derived)
        }
        return out
    }

    static func settleScheduledCourierReview(_ item: ScheduledCourierReview) -> String {
        return classifySpecimenQuota(item.projectedExposure())
    }
}
