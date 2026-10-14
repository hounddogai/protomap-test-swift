import AcmePlatform
import Foundation

extension CareManagement {
    static func summarizeGlobalOutreachThresholdsForReview(_ items: [GlobalOutreachThreshold]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func derivePendingGoalReviewsFromThreshold(_ items: [GlobalOutreachThreshold]) -> [PendingGoalReview] {
        var out: [PendingGoalReview] = []
        for item in items {
            let derived = newPendingGoalReview(item.code + "-plan", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func derivePendingGoalReview(_ item: PendingGoalReview) -> String {
        return normalizeGlobalOutreachThresholdCode(item.code)
    }
}
