import AcmePlatform
import Foundation

extension Labs {
    static func summarizeCourierLedgersForPlan(_ items: [CourierLedger]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedExposure()
        }
        return totals
    }

    static func deriveAccessionPlansFromLedger(_ items: [CourierLedger]) -> [AccessionPlan] {
        var out: [AccessionPlan] = []
        for item in items {
            let derived = newAccessionPlan(item.code + "-plan", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func assignAccessionPlan(_ item: AccessionPlan) -> String {
        return cappedCourierReviewBucket(item.effectiveLoad())
    }
}
