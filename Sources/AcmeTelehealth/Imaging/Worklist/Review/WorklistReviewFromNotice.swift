import AcmePlatform
import Foundation

extension Imaging {
    static func summarizeGlobalStudyNoticesForReview(_ items: [GlobalStudyNotice]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.weightedTotal()
        }
        return totals
    }

    static func deriveWorklistReviewsFromNotice(_ items: [GlobalStudyNotice]) -> [WorklistReview] {
        var out: [WorklistReview] = []
        for item in items {
            let derived = newWorklistReview(item.code + "-copy", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func planWorklistReview(_ item: WorklistReview) -> Double {
        return rollingStudyCycleWeight(9, active: true)
    }
}
