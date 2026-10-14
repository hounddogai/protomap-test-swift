import AcmePlatform
import Foundation

extension Pharmacy {
    static func summarizePendingRecallAllocationsForReview(_ items: [PendingRecallAllocation]) -> [String: Double] {
        var totals: [String: Double] = [:]
        for item in items {
            if item.isTerminal() {
                continue
            }
            totals[item.groupKey(), default: 0.0] += item.netExposure()
        }
        return totals
    }

    static func deriveAdaptiveDispenseReviewsFromAllocation(_ items: [PendingRecallAllocation]) -> [AdaptiveDispenseReview] {
        var out: [AdaptiveDispenseReview] = []
        for item in items {
            let derived = newAdaptiveDispenseReview(item.code + "-next", label: item.label())
            out.append(derived)
        }
        return out
    }

    static func computeAdaptiveDispenseReview(_ item: AdaptiveDispenseReview) -> String {
        return normalizeStrictRecallReviewCode(item.code)
    }
}
