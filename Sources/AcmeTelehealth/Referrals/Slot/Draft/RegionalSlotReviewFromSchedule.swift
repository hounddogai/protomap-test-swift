import AcmePlatform
import Foundation

extension Referrals {
    static func summarizeFallbackNetworkSchedulesForReview(_ items: [FallbackNetworkSchedule]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.projectedVolume()
        }
        return totals
    }

    static func deriveRegionalSlotReviewsFromSchedule(_ items: [FallbackNetworkSchedule]) -> [RegionalSlotReview] {
        var out: [RegionalSlotReview] = []
        for item in items {
            let derived = newRegionalSlotReview(item.code + "-copy", title: item.label())
            out.append(derived)
        }
        return out
    }

    static func reconcileRegionalSlotReview(_ item: RegionalSlotReview) -> String {
        return normalizeNetworkReviewCode(item.code)
    }
}
