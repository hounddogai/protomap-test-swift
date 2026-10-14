import AcmePlatform
import Foundation

extension ClinicalOps {
    static func summarizePendingAlertReviewsForClaim(_ items: [PendingAlertReview]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveTaskClaimsFromReview(_ items: [PendingAlertReview]) -> [TaskClaim] {
        var out: [TaskClaim] = []
        for item in items {
            let derived = newTaskClaim(item.code + "-next", name: item.displayLabel())
            out.append(derived)
        }
        return out
    }

    static func reconcileTaskClaim(_ item: TaskClaim) -> String {
        return normalizePendingAlertReviewCode(item.code)
    }
}
